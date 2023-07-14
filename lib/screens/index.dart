import 'package:agora/screens/call.dart';
import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class IndexPage extends StatefulWidget {
  const IndexPage({super.key});

  @override
  State<IndexPage> createState() => _IndexPageState();
}

class _IndexPageState extends State<IndexPage> {
  final _channelController = TextEditingController();
  bool _validator = false;
  dynamic clientRole = ClientRole.Broadcaster;

  @override
  void dispose() {
    _channelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Agora",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
          child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(children: [
          SizedBox(height: 40),
          Image.network(
              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSuHxTOtf1a1vG6rst6qHS4bEMnyd0-x0KHCGCwLkqlTm-79fCxw2-56Pr-pJvmFHdd1e8&usqp=CAU'),
          TextField(
            controller: _channelController,
            decoration: InputDecoration(
                errorText: _validator ? "Channel name is mandatory" : null,
                hintText: "Channel name"),
          ),
          RadioListTile(
              title: Text("Broadcaster"),
              value: ClientRole.Broadcaster,
              groupValue: clientRole,
              onChanged: (e) {
                setState(() {
                  clientRole = e;
                });
              }),
          RadioListTile(
              title: Text("Auidence"),
              value: ClientRole.Audience,
              groupValue: clientRole,
              onChanged: (e) {
                setState(() {
                  clientRole = e;
                });
              }),
          ElevatedButton(
            onPressed: onjoin,
            child: Text(
              "Join",
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 40),
                backgroundColor: Colors.green),
          )
        ]),
      )),
    );
  }

  Future<void> onjoin() async {
    setState(() {
      _channelController.text.isEmpty ? _validator = true : _validator = false;
    });
    if (_channelController.text.isNotEmpty) {
      await _handeleCameraAndMic(Permission.camera);
      await _handeleCameraAndMic(Permission.audio);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CallPage(
            channelname: _channelController.text,
            role: clientRole,
          ),
        ),
      );
    }
  }

  Future<void> _handeleCameraAndMic(Permission permissionType) async {
    final status = await permissionType.request();
  }
}
