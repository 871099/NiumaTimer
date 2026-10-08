# 第三方运行依赖

Windows 下载包动态链接未经本项目修改的 Qt 6.8.3，包括 Qt Core、GUI、Network、QML、Quick、Quick Controls 2 和部署工具选择的插件/依赖。Qt 开源许可证及所用模块的第三方版权/许可资料随下载包置于 `licenses/Qt-6.8.3/`。

Qt 6.8.3 对应源码可从 [Qt 官方源码下载目录](https://download.qt.io/official_releases/qt/6.8/6.8.3/single/) 获取。动态库单独提供；用户可以用兼容的修改版 Qt 库替换这些库来调试或使用自己的 Qt 实现。应用构建步骤见 [项目 README](https://github.com/871099/NiumaTimer#构建要求)。

Microsoft Visual C++ x64 运行库安装程序随 Windows 包提供，用于安装应用依赖的 MSVC 运行环境，其授权以安装程序所附条款为准。

本项目的像素素材来源和生成记录见 `assets/ARTWORK.md`。第三方依赖的许可证不改变本项目自有源码与素材的授权范围。
