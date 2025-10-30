import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin_updated/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin_updated/datatypes/config_planedetection.dart';
import 'package:ar_flutter_plugin_updated/datatypes/node_types.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin_updated/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin_updated/models/ar_anchor.dart';
import 'package:ar_flutter_plugin_updated/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin_updated/models/ar_node.dart';
import 'package:ar_flutter_plugin_updated/widgets/ar_view.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Fullscreen immersive mode (hides system bars). Use immersiveSticky if you
  // prefer the bars to reappear briefly on swipe.
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Hanal 3D - AR Día de Muertos',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        brightness: Brightness.dark,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hanal 3D'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 100,
                    color: Colors.deepOrange,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Decora tu Altar',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Día de Muertos',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ARScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.camera_alt, size: 28),
                    label: const Text(
                      'Abrir Cámara AR',
                      style: TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ARScreen extends StatefulWidget {
  const ARScreen({super.key});

  @override
  State<ARScreen> createState() => _ARScreenState();
}

class _ARScreenState extends State<ARScreen> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;

  List<ARNode> nodes = [];
  int currentModelIndex = 0;
  String? selectedNodeName;
  bool gesturesEnabledForSelected = true;
  
  // Scale and rotation controls for selected node
  double selectedNodeScale = 0.2;
  double selectedNodeRotationX = 0.0;
  double selectedNodeRotationY = 0.0;
  double selectedNodeRotationZ = 0.0;

  // Lista de modelos 3D disponibles
  final List<Map<String, String>> models = [
    {
      'name': 'Altar',
      'path': 'assets/altar_de_dia_de_muertos.glb',
    },
    {
      'name': 'Altar Robin Williams',
      'path': 'assets/altar_del_dia_de_muertos_robin_williams.glb',
    },
    {
      'name': 'Calaveras',
      'path': 'assets/calaveras.glb',
    },
    {
      'name': 'Candelabro 2 Velas',
      'path': 'assets/candelabro-2-velas.glb',
    },
    {
      'name': 'Día de Muertos',
      'path': 'assets/dia_de_los_muertos.glb',
    },
    {
      'name': 'Katrina',
      'path': 'assets/dia_de_los_muertos_katrina_mexico.glb',
    },
    {
      'name': 'Flor de Calavera',
      'path': 'assets/flor_de_calavera.glb',
    },
    {
      'name': 'Pan de Muerto',
      'path': 'assets/pan_de_muerto.glb',
    },
    {
      'name': 'Papel Picado',
      'path': 'assets/papel_picado.glb',
    },
    {
      'name': 'Porta Velas Cerámica',
      'path': 'assets/porta_velas_artesanal_ceramica.glb',
    },
    {
      'name': 'Ribeye',
      'path': 'assets/ribeye.glb',
    },
    {
      'name': 'Calavera',
      'path': 'assets/skull_dia_de_muertos.glb',
    },
    {
      'name': 'Vasija Corteza',
      'path': 'assets/vasija_estilo_cortezo_proyeccion.glb',
    },
  ];

  @override
  void dispose() {
    arSessionManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decoración AR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _removeAllObjects,
            tooltip: 'Eliminar todos los objetos',
          ),
        ],
      ),
      body: Stack(
        children: [
          ARView(
            onARViewCreated: onARViewCreated,
            planeDetectionConfig: PlaneDetectionConfig.horizontalAndVertical,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Selector de modelo
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: [
                        Text(
                          models[currentModelIndex]['name']!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios),
                              onPressed: () {
                                setState(() {
                                  currentModelIndex = (currentModelIndex - 1) % models.length;
                                });
                              },
                            ),
                            const SizedBox(width: 20),
                            Text('${currentModelIndex + 1} / ${models.length}'),
                            const SizedBox(width: 20),
                            IconButton(
                              icon: const Icon(Icons.arrow_forward_ios),
                              onPressed: () {
                                setState(() {
                                  currentModelIndex = (currentModelIndex + 1) % models.length;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Instrucciones
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      'Toca sobre una superficie para colocar el objeto',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Per-node controls (visible when a node is selected)
                if (selectedNodeName != null)
                  Card(
                    color: Colors.black87,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          Text('Seleccionado: $selectedNodeName', 
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          
                          // Scale slider
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Escala: ${selectedNodeScale.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14)),
                              Slider(
                                value: selectedNodeScale,
                                min: 0.05,
                                max: 1.0,
                                divisions: 95,
                                onChanged: (value) {
                                  setState(() {
                                    selectedNodeScale = value;
                                  });
                                  _updateSelectedNodeTransform();
                                },
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 8),
                          const Divider(),
                          const SizedBox(height: 8),
                          
                          // Rotation sliders
                          const Text('Rotación', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          
                          // Rotation X
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Eje X: ${(selectedNodeRotationX * 180 / 3.14159).toStringAsFixed(0)}°',
                                style: const TextStyle(fontSize: 12)),
                              Slider(
                                value: selectedNodeRotationX,
                                min: -3.14159,
                                max: 3.14159,
                                onChanged: (value) {
                                  setState(() {
                                    selectedNodeRotationX = value;
                                  });
                                  _updateSelectedNodeTransform();
                                },
                              ),
                            ],
                          ),
                          
                          // Rotation Y
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Eje Y: ${(selectedNodeRotationY * 180 / 3.14159).toStringAsFixed(0)}°',
                                style: const TextStyle(fontSize: 12)),
                              Slider(
                                value: selectedNodeRotationY,
                                min: -3.14159,
                                max: 3.14159,
                                onChanged: (value) {
                                  setState(() {
                                    selectedNodeRotationY = value;
                                  });
                                  _updateSelectedNodeTransform();
                                },
                              ),
                            ],
                          ),
                          
                          // Rotation Z
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Eje Z: ${(selectedNodeRotationZ * 180 / 3.14159).toStringAsFixed(0)}°',
                                style: const TextStyle(fontSize: 12)),
                              Slider(
                                value: selectedNodeRotationZ,
                                min: -3.14159,
                                max: 3.14159,
                                onChanged: (value) {
                                  setState(() {
                                    selectedNodeRotationZ = value;
                                  });
                                  _updateSelectedNodeTransform();
                                },
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          
                          Row(
                            children: [
                              const Text('Gestos táctiles'),
                              const Spacer(),
                              Switch(
                                value: gesturesEnabledForSelected,
                                onChanged: (v) {
                                  setState(() {
                                    gesturesEnabledForSelected = v;
                                  });
                                },
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  // Remove selected node safely
                                  if (selectedNodeName == null) return;
                                  
                                  final nodeToRemove = selectedNodeName;
                                  setState(() {
                                    selectedNodeName = null;
                                  });
                                  
                                  try {
                                    final node = nodes.firstWhere(
                                      (n) => n.name == nodeToRemove,
                                      orElse: () => throw StateError('Node not found'),
                                    );
                                    await arObjectManager?.removeNode(node);
                                    setState(() {
                                      nodes.removeWhere((n) => n.name == nodeToRemove);
                                    });
                                    print('Node removed: $nodeToRemove');
                                  } catch (e) {
                                    print('Error removing node: $e');
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: const Text('Eliminar'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    selectedNodeName = null;
                                  });
                                },
                                child: const Text('Deseleccionar'),
                              ),
                            ),
                          ])
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager!.onInitialize(
          showFeaturePoints: false,
          showPlanes: true,
          showWorldOrigin: false,
          handlePans: true,
          handleRotation: true,
        );
    this.arObjectManager!.onInitialize();

    this.arSessionManager!.onPlaneOrPointTap = onPlaneOrPointTapped;
    this.arObjectManager!.onPanStart = onPanStarted;
    this.arObjectManager!.onPanChange = onPanChanged;
    this.arObjectManager!.onPanEnd = onPanEnded;
    this.arObjectManager!.onRotationStart = onRotationStarted;
    this.arObjectManager!.onRotationChange = onRotationChanged;
    this.arObjectManager!.onRotationEnd = onRotationEnded;
    this.arObjectManager!.onNodeTap = onNodeTapped;
  }

  Future<void> onPlaneOrPointTapped(List<ARHitTestResult> hitTestResults) async {
    var singleHitTestResult = hitTestResults.firstOrNull;
    if (singleHitTestResult != null) {
      var newAnchor = ARPlaneAnchor(transformation: singleHitTestResult.worldTransform);
      bool? didAddAnchor = await arAnchorManager?.addAnchor(newAnchor);
      
      if (didAddAnchor!) {
        // Copy asset to app's Documents folder and use fileSystemAppFolderGLB type
        // This is the correct way to load local GLB models for ar_flutter_plugin
        String assetPath = models[currentModelIndex]['path']!;
        String modelUri;
        
        try {
          modelUri = await _copyAssetToDocuments(assetPath);
          print('Copied model to documents: $modelUri');
        } catch (e) {
          print('Error copying asset: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al cargar modelo: $e')),
            );
          }
          return;
        }

        // Create AR node using fileSystemAppFolderGLB type
        var newNode = ARNode(
          type: NodeType.fileSystemAppFolderGLB,
          uri: modelUri,  // Just the filename, not the full path
          scale: vector.Vector3(0.2, 0.2, 0.2),
          position: vector.Vector3(0.0, 0.0, 0.0),
          rotation: vector.Vector4(1.0, 0.0, 0.0, 0.0),
        );

        bool? didAddNodeToAnchor = await arObjectManager?.addNode(newNode, planeAnchor: newAnchor);

        if (didAddNodeToAnchor!) {
          nodes.add(newNode);
          print("Modelo agregado exitosamente: ${models[currentModelIndex]['name']}");
        } else {
          print("No se pudo agregar el modelo");
        }
      } else {
        print("No se pudo agregar el anchor");
      }
    }
  }

  // Called when the user taps a node in the AR scene
  Future<void> onNodeTapped(List<String> nodeNames) async {
    if (nodeNames.isEmpty) return;
    final tapped = nodeNames.first;
    setState(() {
      if (selectedNodeName == tapped) {
        // toggle selection off if tapped again
        selectedNodeName = null;
      } else {
        selectedNodeName = tapped;
        // Load current node's transform values
        try {
          final node = nodes.firstWhere((n) => n.name == tapped);
          // Extract scale from the node's scale vector
          selectedNodeScale = node.scale.x; // Assuming uniform scale
          
          // Reset rotation sliders to 0 when selecting a new node
          // (tracking rotation from Matrix3 is complex, start fresh)
          selectedNodeRotationX = 0.0;
          selectedNodeRotationY = 0.0;
          selectedNodeRotationZ = 0.0;
        } catch (e) {
          print('Error loading node transform: $e');
        }
      }
    });
    print('Node tapped: $tapped (selected: $selectedNodeName)');
  }

  onPanStarted(String nodeName) {
    // Only allow panning if this node is selected (individual control)
    if (selectedNodeName == null || selectedNodeName != nodeName || !gesturesEnabledForSelected) return;
    print("Started panning node $nodeName");
  }

  onPanChanged(String nodeName) {
    if (selectedNodeName == null || selectedNodeName != nodeName || !gesturesEnabledForSelected) return;
    print("Continued panning node $nodeName");
  }

  onPanEnded(String nodeName, Matrix4 newTransform) {
    if (selectedNodeName == null || selectedNodeName != nodeName || !gesturesEnabledForSelected) return;
    print("Ended panning node $nodeName");
    final pannedNode = nodes.firstWhere((element) => element.name == nodeName);
    pannedNode.transform = newTransform;
  }

  onRotationStarted(String nodeName) {
    if (selectedNodeName == null || selectedNodeName != nodeName || !gesturesEnabledForSelected) return;
    print("Started rotating node $nodeName");
  }

  onRotationChanged(String nodeName) {
    if (selectedNodeName == null || selectedNodeName != nodeName || !gesturesEnabledForSelected) return;
    print("Continued rotating node $nodeName");
  }

  onRotationEnded(String nodeName, Matrix4 newTransform) {
    if (selectedNodeName == null || selectedNodeName != nodeName || !gesturesEnabledForSelected) return;
    print("Ended rotating node $nodeName");
    final rotatedNode = nodes.firstWhere((element) => element.name == nodeName);
    rotatedNode.transform = newTransform;
  }

  /// Copies a Flutter asset to the app's Documents directory
  /// Returns just the filename (not the full path) for use with NodeType.fileSystemAppFolderGLB
  Future<String> _copyAssetToDocuments(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final buffer = byteData.buffer;
    
    // Get the app's documents directory
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    
    // Extract just the filename from the asset path
    final String filename = assetPath.split('/').last;
    
    // Create the file in the documents directory
    final File file = File('${appDocDir.path}/$filename');
    
    // Write the asset bytes to the file
    await file.writeAsBytes(
      buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes),
    );
    
    print('File copied to: ${file.path}');
    print('File exists: ${await file.exists()}');
    
    // Return just the filename (the plugin will look in the documents folder)
    return filename;
  }

  /// Updates the transform (scale and rotation) of the currently selected node
  Future<void> _updateSelectedNodeTransform() async {
    if (selectedNodeName == null) return;
    
    try {
      final node = nodes.firstWhere(
        (n) => n.name == selectedNodeName,
        orElse: () => throw StateError('Node not found: $selectedNodeName'),
      );
      
      // Update scale
      node.scale = vector.Vector3(selectedNodeScale, selectedNodeScale, selectedNodeScale);
      
      // Create rotation matrix from euler angles
      final rotMatrix = _eulerToRotationMatrix(selectedNodeRotationX, selectedNodeRotationY, selectedNodeRotationZ);
      node.rotation = rotMatrix;
      
      // Apply the transform to the AR scene
      // Note: The plugin will automatically update the visual representation
      print('Updated transform for $selectedNodeName - Scale: $selectedNodeScale, Rotation: ($selectedNodeRotationX, $selectedNodeRotationY, $selectedNodeRotationZ)');
      
    } catch (e) {
      print('Error updating node transform: $e');
      // If node doesn't exist, deselect it
      if (mounted) {
        setState(() {
          selectedNodeName = null;
        });
      }
    }
  }

  /// Converts euler angles (radians) to rotation matrix
  vector.Matrix3 _eulerToRotationMatrix(double x, double y, double z) {
    // Rotation matrix for X axis
    final cx = cos(x);
    final sx = sin(x);
    // Rotation matrix for Y axis
    final cy = cos(y);
    final sy = sin(y);
    // Rotation matrix for Z axis
    final cz = cos(z);
    final sz = sin(z);

    // Combined rotation matrix (ZYX order)
    return vector.Matrix3(
      cy * cz, -cy * sz, sy,
      sx * sy * cz + cx * sz, -sx * sy * sz + cx * cz, -sx * cy,
      -cx * sy * cz + sx * sz, cx * sy * sz + sx * cz, cx * cy,
    );
  }

  Future<void> _removeAllObjects() async {
    for (var node in nodes) {
      await arObjectManager?.removeNode(node);
    }
    nodes.clear();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Todos los objetos han sido eliminados'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
