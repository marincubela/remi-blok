import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:kartaski_blok/remi_repository.dart';

class RemiStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/Remi_blok.txt');
  }

  Future<RemiRepository> readRemi() async {
    try {
      final file = await _localFile;

      // Read the file
      final contents = await file.readAsString();

      final json = jsonDecode(contents) as Map<String, dynamic>;

      var repository = RemiRepository.fromJson(json);

      return repository;
    } catch (e) {
      return RemiRepository(["", ""]);
    }
  }

  Future<File> writeRemi(RemiRepository repository) async {
    final file = await _localFile;

    // Write the file
    return file.writeAsString(jsonEncode(repository));
  }
}