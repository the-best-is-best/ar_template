import 'package:ar_flutter_plugin/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/models/ar_anchor.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:ar_flutter_plugin/widgets/ar_view.dart';
import 'package:ar_tester/functions.dart';
import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:vector_math/vector_math_64.dart' as vector;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'AR Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late ARSessionManager arSessionManager;
  late ARObjectManager arObjectManager;
  late ARAnchorManager arAnchorManager;

  List<ARNode> nodes = [];
  List<ARAnchor> anchors = [];
  @override
  void dispose() {
    super.dispose();
    arSessionManager.dispose();
  }

  bool loaded = true;
  double progress = 0;
  String assetsName = "";

  Map<String, String> assets = {
    "sofa":
        "https://github.com/the-best-is-best/ar_template/raw/main/models/sofa.glb",
    "chair":
        "https://github.com/the-best-is-best/ar_template/raw/main/models/chair.glb",
    "table":
        "https://github.com/the-best-is-best/ar_template/raw/main/models/table.glb",
  };

  void onARViewCreated(
      ARSessionManager arSessionManager,
      ARObjectManager arObjectManager,
      ARAnchorManager arAnchorManager,
      ARLocationManager arLocationManager) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager.onInitialize(
          showFeaturePoints: false,
          showPlanes: true,
          customPlaneTexturePath: "assets/images/triangle.png",
          showWorldOrigin: true,
          handlePans: true,
          handleRotation: true,
        );
    this.arObjectManager.onInitialize();

    this.arSessionManager.onPlaneOrPointTap = onPlaneOrPointTapped;
    this.arObjectManager.onNodeTap = onNodeTapped;
    this.arObjectManager.onPanStart = onPanStarted;
    this.arObjectManager.onPanChange = onPanChanged;
    this.arObjectManager.onPanEnd = onPanEnded;
    this.arObjectManager.onRotationStart = onRotationStarted;
    this.arObjectManager.onRotationChange = onRotationChanged;
    this.arObjectManager.onRotationEnd = onRotationEnded;
  }

  onPanStarted(String nodeName) {
    debugPrint("Started panning node $nodeName");
  }

  onPanChanged(String nodeName) {
    debugPrint("Continued panning node $nodeName");
  }

  onPanEnded(String nodeName, Matrix4 newTransform) {
    debugPrint("Ended panning node " + nodeName);
    // final pannedNode =
    //     this.nodes.firstWhere((element) => element.name == nodeName);

    /*
    * Uncomment the following command if you want to keep the transformations of the Flutter representations of the nodes up to date
    * (e.g. if you intend to share the nodes through the cloud)
    */
    //pannedNode.transform = newTransform;
  }

  onRotationStarted(String nodeName) {
    debugPrint("Started rotating node $nodeName");
  }

  onRotationChanged(String nodeName) {
    debugPrint("Continued rotating node $nodeName");
  }

  onRotationEnded(String nodeName, Matrix4 newTransform) {
    debugPrint("Ended rotating node $nodeName");
    // final rotatedNode =
    //     this.nodes.firstWhere((element) => element.name == nodeName);

    /*
    * Uncomment the following command if you want to keep the transformations of the Flutter representations of the nodes up to date
    * (e.g. if you intend to share the nodes through the cloud)
    */
    //rotatedNode.transform = newTransform;
  }

  Future<void> onRemoveEverything() async {
    for (var anchor in anchors) {
      arAnchorManager.removeAnchor(anchor);
    }

    anchors = [];
  }

  Future<void> onTakeScreenshot() async {
    var image = await arSessionManager.snapshot();
    await showDialog(
        context: context,
        builder: (_) => Dialog(
              child: Container(
                decoration: BoxDecoration(
                    image: DecorationImage(image: image, fit: BoxFit.cover)),
              ),
            ));
  }

  Future<void> onNodeTapped(List<String> nodes) async {
    var number = nodes.length;
    arSessionManager.onError("Tapped $number node(s)");
  }

  Future<void> onPlaneOrPointTapped(
      List<ARHitTestResult> hitTestResults) async {
    if (assetsName.isNotEmpty) {
      try {
        var singleHitTestResult = hitTestResults.firstWhere(
            (hitTestResult) => hitTestResult.type == ARHitTestResultType.plane);
        var newAnchor =
            ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
        bool didAddAnchor = await arAnchorManager.addAnchor(newAnchor) ?? false;
        if (didAddAnchor) {
          anchors.add(newAnchor);
          // Add note to anchor
          var newNode = ARNode(
              type: NodeType.fileSystemAppFolderGLB,
              uri: assetsName,
              scale: vector.Vector3(.2, .2, .2),
              position: vector.Vector3(0.0, 0.0, 0.0),
              rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0));
          bool didAddNodeToAnchor =
              await arObjectManager.addNode(newNode, planeAnchor: newAnchor) ??
                  false;

          if (didAddNodeToAnchor) {
            nodes.add(newNode);
          } else {
            arSessionManager.onError("Adding Node to Anchor failed");
          }
        } else {
          arSessionManager.onError("Adding Anchor failed");
        }
      } catch (ex) {
        arSessionManager.onError('anchor error');
      }
    } else {
      arSessionManager.onError('No Assets Selected');
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
        ),
        actions: [
          ...assets.entries
              .map(
                (MapEntry e) => SizedBox(
                  width: 80,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        assetsName = e.key;
                      });
                      downloadAsset(
                          url: e.value,
                          filename: e.key,
                          callWhenFileDownload: () {
                            setState(() {
                              loaded = false;
                            });
                          },
                          onReceiveProgress: (rcv, total) {
                            setState(() {
                              progress = rcv / total;
                            });
                          },
                          callWhenFileDownloaded: () {
                            setState(() {
                              progress = 0;
                              loaded = true;
                              assetsName = e.key;
                            });
                          });
                    },
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Text(
                            e.key,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        SizedBox(
                            width: 10,
                            child: Checkbox(
                                value: e.key == assetsName, onChanged: (v) {}))
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
          const SizedBox(width: 10),
        ],
      ),
      body: !loaded
          ? DownloadItem(progress: progress)
          : Stack(
              children: [
                ARView(
                  onARViewCreated: onARViewCreated,
                  planeDetectionConfig:
                      PlaneDetectionConfig.horizontalAndVertical,
                ),
                Align(
                  alignment: FractionalOffset.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                          onPressed: onRemoveEverything,
                          child: const Text("Remove Everything")),
                      ElevatedButton(
                          onPressed: onTakeScreenshot,
                          child: const Text("Take Screenshot")),
                    ],
                  ),
                )
              ],
            ),
    );
  }
}

class DownloadItem extends StatelessWidget {
  const DownloadItem({
    Key? key,
    required this.progress,
  }) : super(key: key);

  final double progress;

  @override
  Widget build(BuildContext context) {
    return LinearPercentIndicator(
      width: MediaQuery.of(context).size.width,
      lineHeight: 10.0,
      percent: progress,
      backgroundColor: Colors.grey,
      progressColor: Colors.blue,
    );
  }
}
