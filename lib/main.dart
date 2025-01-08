import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:translator/translator.dart'; // For translation
import 'package:flutter_tts/flutter_tts.dart'; // For text-to-speech

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Startapp(),
    );
  }
}

class Startapp extends StatefulWidget {
  @override
  _StartappState createState() => _StartappState();
}

class _StartappState extends State<Startapp> {
  File? _image;
  String? _caption;

  // Fonction pour sélectionner une image et l'uploader
  Future<void> _pickImage(BuildContext context) async {
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          _caption = null; // Réinitialiser la légende précédente
        });
        // Naviguer vers la page d'upload
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UploadingPage(),
          ),
        );
        await _uploadImage(_image!, context); // Upload de l'image
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<void> _uploadImage(File imageFile, BuildContext context) async {
    final apiUrl =
        'http://192.168.31.46:5000/generate_caption'; // Remplacez avec l'URL de votre API

    try {
      // Préparer le fichier d'image pour l'upload
      final request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));

      // Envoyer la requête
      final response = await request.send();

      if (response.statusCode == 200) {
        // Analyser la réponse
        final responseBody = await response.stream.bytesToString();
        final decodedResponse = jsonDecode(responseBody);
        setState(() {
          _caption = decodedResponse['caption']; // Légende retournée par l'API
        });

        // Naviguer vers la page de la légende après l'upload
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CaptionDisplayPage(
              image: _image!,
              caption: _caption!,
            ),
          ),
        );
      } else {
        print("Error: API responded with status code ${response.statusCode}");
      }
    } catch (e) {
      print("Error during image upload: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 110, 166, 240),
              Color.fromARGB(255, 191, 212, 218)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 60),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Image.asset(
                'assets/cat.png', // Remplace par le chemin de ton image
                height: 230,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(height: 40),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(85),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Let's Start",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Discover the power of image recognition! Generate captions and detect objects in your photos with ease.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                      Spacer(),
                      ElevatedButton(
                        onPressed: () => _pickImage(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 75, 184, 79),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                        ),
                        child: Text(
                          "Get Started",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UploadingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Texte affichant "Uploading..."
            Text(
              "Uploading...",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue, // Vous pouvez ajuster la couleur
              ),
            ),
            SizedBox(height: 20), // Espacement entre le texte et le loader
            // Indicateur de progression
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class CaptionDisplayPage extends StatefulWidget {
  final File image;
  final String caption;

  CaptionDisplayPage({required this.image, required this.caption});

  @override
  _CaptionDisplayPageState createState() => _CaptionDisplayPageState();
}

class _CaptionDisplayPageState extends State<CaptionDisplayPage> {
  final FlutterTts flutterTts = FlutterTts(); // Pour la synthèse vocale
  final GoogleTranslator translator = GoogleTranslator(); // Pour la traduction
  String translatedCaption = "";
  String currentLanguage = "en"; // Langue actuelle (par défaut : anglais)
  String currentLanguageName = "English"; // Nom de la langue actuelle

  // Liste des langues disponibles
  final Map<String, String> languages = {
    "en": "English",
    "fr": "French",
    "ar": "Arabic",
  };

  @override
  void initState() {
    super.initState();
    translatedCaption = widget.caption; // Initialiser avec la légende originale
  }

  // Fonction pour traduire le texte
  Future<void> _translateText(String targetLanguage) async {
    try {
      final translation =
          await translator.translate(widget.caption, to: targetLanguage);
      setState(() {
        translatedCaption = translation.text;
        currentLanguage = targetLanguage;
        currentLanguageName = languages[targetLanguage]!;
      });
    } catch (e) {
      print("Erreur lors de la traduction : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la traduction.")),
      );
    }
  }

  // Fonction pour lire le texte avec Text-to-Speech
  Future<void> _speakText() async {
    try {
      switch (currentLanguage) {
        case 'fr':
          await flutterTts.setLanguage("fr-FR"); // Français
          break;
        case 'ar':
          await flutterTts.setLanguage("ar-SA"); // Arabe
          break;
        case 'en':
        default:
          await flutterTts.setLanguage("en-US"); // Anglais
          break;
      }

      await flutterTts.setSpeechRate(0.5); // Débit de parole
      await flutterTts.speak(translatedCaption);
    } catch (e) {
      print("Erreur lors de la synthèse vocale : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur lors de la synthèse vocale.")),
      );
    }
  }

  // Fonction pour sélectionner une langue
  Future<void> _selectLanguage() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Select Language"),
          content: Container(
            width: double.minPositive,
            child: ListView(
              shrinkWrap: true,
              children: languages.entries.map((entry) {
                return ListTile(
                  title: Text(entry.value),
                  onTap: () {
                    Navigator.of(context).pop();
                    _translateText(entry
                        .key); // Traduire le texte dans la langue sélectionnée
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Image Caption"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 5,
              child: Column(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height / 2,
                    width: double.infinity,
                    child: Image.file(
                      widget.image,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      translatedCaption,
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            // Boutons pour sélection de langue, traduction et synthèse vocale
            Card(
              elevation: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    onPressed: () {
                      _selectLanguage(); // Ouvrir la liste des langues
                    },
                    icon: Icon(Icons.language),
                    color: Colors.blue,
                  ),
                  IconButton(
                    onPressed: () {
                      _speakText(); // Lire la légende
                    },
                    icon: Icon(Icons.volume_up),
                    color: Colors.green,
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Current Language: $currentLanguageName",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
