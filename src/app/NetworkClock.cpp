// 使用异步 NTP 请求校准时间；网络不可用时沿用上次校准或设备时间。
#include "NetworkClock.h"

#include <QtGlobal>

#include <algorithm>
#include <cmath>

namespace {
constexpr auto kNtpHost = "time.cloudflare.com";
constexpr quint16 kNtpPort = 123;
constexpr qint64 kNtpEpochOffsetSeconds = 2208988800LL;
constexpr qint64 kNtpEraSeconds = 4294967296LL;
constexpr int kNtpPacketSize = 48;
constexpr int kRetryIntervalMs = 60 * 1000;
constexpr int kSyncIntervalMs = 60 * 60 * 1000;
constexpr int kRequestTimeoutMs = 8 * 1000;
}

NetworkClock::NetworkClock(QObject *parent) : QObject(parent) {
    syncTimer_.setSingleShot(true);
    timeoutTimer_.setSingleShot(true);
    timeoutTimer_.setInterval(kRequestTimeoutMs);

    connect(&socket_, &QUdpSocket::readyRead, this, &NetworkClock::readResponses);
    connect(&syncTimer_, &QTimer::timeout, this, &NetworkClock::syncNow);
    connect(&timeoutTimer_, &QTimer::timeout, this, [this] {
        if (lookupId_ >= 0) QHostInfo::abortHostLookup(lookupId_);
        lookupId_ = -1;
        finishFailure();
    });

    QTimer::singleShot(0, this, &NetworkClock::syncNow);
}

QDateTime NetworkClock::currentDateTime() const {
    if (!anchorUtc_.isValid()) return QDateTime::currentDateTime();
    return anchorUtc_.addMSecs(anchorElapsed_.elapsed()).toLocalTime();
}

void NetworkClock::syncNow() {
    if (requestPending_) {
        if (lookupId_ >= 0) QHostInfo::abortHostLookup(lookupId_);
        lookupId_ = -1;
        requestPending_ = false;
        timeoutTimer_.stop();
    }

    requestPending_ = true;
    setStatusText(anchorUtc_.isValid()
        ? QStringLiteral("正在更新网络时间 · 沿用上次校准")
        : QStringLiteral("正在同步网络时间"));
    timeoutTimer_.start();

    // DNS 查询异步执行，避免网络慢时阻塞首页倒计时。
    lookupId_ = QHostInfo::lookupHost(QString::fromLatin1(kNtpHost), this,
        [this](const QHostInfo &hostInfo) {
            lookupId_ = -1;
            if (!requestPending_) return;
            if (hostInfo.error() != QHostInfo::NoError || hostInfo.addresses().isEmpty()) {
                finishFailure();
                return;
            }
            sendRequest(hostInfo);
        });
}

void NetworkClock::sendRequest(const QHostInfo &hostInfo) {
    serverAddress_ = hostInfo.addresses().first();
    QByteArray packet(kNtpPacketSize, '\0');
    packet[0] = static_cast<char>(0x23); // LI=0、VN=4、Mode=3（客户端）
    requestTimestamp_ = std::max(requestTimestamp_ + 1,
                                 makeNtpTimestamp(QDateTime::currentDateTimeUtc()));
    for (int byte = 0; byte < 8; ++byte) {
        packet[40 + byte] = static_cast<char>(requestTimestamp_ >> (56 - byte * 8));
    }

    requestElapsed_.start();
    const qint64 sent = socket_.writeDatagram(packet, serverAddress_, kNtpPort);
    if (sent != packet.size()) finishFailure();
}

void NetworkClock::readResponses() {
    while (socket_.hasPendingDatagrams()) {
        QByteArray packet(static_cast<qsizetype>(socket_.pendingDatagramSize()), '\0');
        QHostAddress sender;
        quint16 senderPort = 0;
        const qint64 bytes = socket_.readDatagram(packet.data(), packet.size(),
                                                  &sender, &senderPort);
        if (!requestPending_ || bytes < kNtpPacketSize ||
            sender != serverAddress_ || senderPort != kNtpPort) {
            continue;
        }

        const auto *data = reinterpret_cast<const uchar *>(packet.constData());
        const int leap = (data[0] >> 6) & 0x03;
        const int mode = data[0] & 0x07;
        const int stratum = data[1];
        quint64 originateTimestamp = 0;
        for (int byte = 0; byte < 8; ++byte) {
            originateTimestamp = (originateTimestamp << 8) |
                                 static_cast<uchar>(packet.at(24 + byte));
        }
        if (leap == 3 || mode != 4 || stratum < 1 || stratum > 15 ||
            originateTimestamp != requestTimestamp_) {
            continue;
        }

        const quint32 seconds = readBigEndian32(packet, 40);
        const quint32 fraction = readBigEndian32(packet, 44);
        if (seconds == 0 && fraction == 0) continue;

        // 选择离本机日期最近的 NTP era，兼容 2036 年秒数字段回绕。
        const qint64 referenceNtpSeconds =
            QDateTime::currentDateTimeUtc().toSecsSinceEpoch() + kNtpEpochOffsetSeconds;
        const qint64 era = static_cast<qint64>(std::llround(
            static_cast<long double>(referenceNtpSeconds - seconds) / kNtpEraSeconds));
        const qint64 unixSeconds = seconds + era * kNtpEraSeconds - kNtpEpochOffsetSeconds;
        qint64 fractionMs = static_cast<qint64>(
            (static_cast<quint64>(fraction) * 1000ULL + 0x80000000ULL) >> 32);
        qint64 serverUnixMs = unixSeconds * 1000 + fractionMs;
        serverUnixMs += requestElapsed_.elapsed() / 2;

        anchorUtc_ = QDateTime::fromMSecsSinceEpoch(serverUnixMs, Qt::UTC);
        anchorElapsed_.restart();
        requestPending_ = false;
        timeoutTimer_.stop();
        syncTimer_.start(kSyncIntervalMs);
        setStatusText(QStringLiteral("网络时间已同步"));
        emit timeSynchronized();
        return;
    }
}

void NetworkClock::finishFailure() {
    if (!requestPending_) return;
    requestPending_ = false;
    timeoutTimer_.stop();
    syncTimer_.start(kRetryIntervalMs);
    setStatusText(anchorUtc_.isValid()
        ? QStringLiteral("网络暂不可用 · 沿用上次校准")
        : QStringLiteral("网络校时失败 · 使用设备时间"));
}

void NetworkClock::setStatusText(const QString &text) {
    if (statusText_ == text) return;
    statusText_ = text;
    emit statusChanged();
}

quint64 NetworkClock::makeNtpTimestamp(const QDateTime &utc) {
    const qint64 unixMs = utc.toMSecsSinceEpoch();
    const quint64 seconds = static_cast<quint64>(unixMs / 1000 + kNtpEpochOffsetSeconds);
    const quint64 milliseconds = static_cast<quint64>(unixMs % 1000);
    const quint64 fraction = (milliseconds << 32) / 1000;
    return (seconds << 32) | fraction;
}

quint32 NetworkClock::readBigEndian32(const QByteArray &data, qsizetype offset) {
    const auto *bytes = reinterpret_cast<const uchar *>(data.constData() + offset);
    return (static_cast<quint32>(bytes[0]) << 24) |
           (static_cast<quint32>(bytes[1]) << 16) |
           (static_cast<quint32>(bytes[2]) << 8) |
           static_cast<quint32>(bytes[3]);
}
