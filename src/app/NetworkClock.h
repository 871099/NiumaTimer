// 网络时钟：异步获取 NTP 时间，并用单调时钟推进校准后的当前时间。
#pragma once

#include <QByteArray>
#include <QElapsedTimer>
#include <QHostAddress>
#include <QHostInfo>
#include <QObject>
#include <QDateTime>
#include <QString>
#include <QTimer>
#include <QUdpSocket>

class NetworkClock final : public QObject {
    Q_OBJECT

public:
    explicit NetworkClock(QObject *parent = nullptr);

    QDateTime currentDateTime() const;
    QString statusText() const { return statusText_; }
    void syncNow();

signals:
    void statusChanged();
    void timeSynchronized();

private:
    // 将主机名解析结果转换为一次 NTP/UDP 请求。
    void sendRequest(const QHostInfo &hostInfo);
    // 校验来源和 originate 时间戳后，采用服务器 transmit 时间校准。
    void readResponses();
    // 网络请求超时或失败时设置回退状态并安排重试。
    void finishFailure();
    void setStatusText(const QString &text);
    // 编解码 NTP 网络字节序时间戳。
    static quint64 makeNtpTimestamp(const QDateTime &utc);
    static quint32 readBigEndian32(const QByteArray &data, qsizetype offset);

    QUdpSocket socket_;
    QTimer syncTimer_;
    QTimer timeoutTimer_;
    QElapsedTimer requestElapsed_;
    QElapsedTimer anchorElapsed_;
    QDateTime anchorUtc_;
    QString statusText_ = QStringLiteral("正在同步网络时间");
    QHostAddress serverAddress_;
    quint64 requestTimestamp_ = 0;
    int lookupId_ = -1;
    bool requestPending_ = false;
};
