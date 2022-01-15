import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:path/path.dart' as path;

class ExmapleDragTarget extends StatefulWidget {
  const ExmapleDragTarget({Key? key}) : super(key: key);

  @override
  _ExmapleDragTargetState createState() => _ExmapleDragTargetState();
}

class _ExmapleDragTargetState extends State<ExmapleDragTarget> {
  final List<XFile> _list = [];
  var tips = "拖动文件到这里～";
  var savePath = '';
  var cmdLog = '';
  final TextEditingController _controller = TextEditingController();

  bool _dragging = false;
  void handleDrage(List<XFile> files) async {
    cmdLog = '';
    tips = '正在发送中，请稍等～～';
    var filePathList = files.map((e) => e.path.toString()).toList();

    final process =
        await Process.start('adb', ['push', ...filePathList, _controller.text]);
    final lineStream = process.stdout
        .transform(const Utf8Decoder())
        .transform(const LineSplitter());

    await for (final line in lineStream) {
      cmdLog += line + '\n';
    }
    print(cmdLog);

    await process.stderr.drain();
    var exitCode = await process.exitCode;

    var simpleFileName = [];
    for (var element in filePathList) {
      simpleFileName.add(path.basename(element));
    }

    setState(() {
      if (exitCode == 0) {
        tips =
            "已经成功发送到手机～\n\n包含以下${files.length}个文件:\n${simpleFileName.join('\n')}";
      } else {
        tips = "发送失败，请检查手机连接以及adb配置";
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _controller.text = '/sdcard/';
    savePath = _controller.text;
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
        onDragDone: (detail) {
          setState(() {
            handleDrage(detail.files);
            _list.addAll(detail.files);
          });
        },
        onDragEntered: (detail) {
          setState(() {
            _dragging = true;
          });
        },
        onDragExited: (detail) {
          setState(() {
            _dragging = false;
            _list.clear();
          });
        },
        child: Stack(
          children: [
            Container(
                height: 400,
                width: 300,
                color:
                    _dragging ? Colors.blue.withOpacity(0.4) : Colors.black26,
                child: _list.isEmpty
                    ? Center(
                        child: Text(
                          tips,
                          style: const TextStyle(fontSize: 25),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tips, style: const TextStyle(fontSize: 20)),
                            const SizedBox(
                              height: 15,
                            ),
                            Text(cmdLog),
                          ],
                        ),
                      )),
            Positioned(
                bottom: 0,
                child: Container(
                  height: 30,
                  width: 300,
                  color: Colors.white,
                  child: Row(
                    children: [
                      const Text('Target:'),
                      Expanded(
                          child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: _controller.text,
                        ),
                      ))
                    ],
                  ),
                ))
          ],
        ));
  }
}
