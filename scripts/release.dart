import 'dart:io';

void main(List<String> args) async {
  print('====================================');
  print('   AUTORELEASE INTHEGRA APP');
  print('====================================\n');
  
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('ERRORE: pubspec.yaml non trovato. Assicurati di eseguire lo script dalla root del progetto.');
    return;
  }

  String content = await pubspecFile.readAsString();
  final versionMatch = RegExp(r'^version: (.*)', multiLine: true).firstMatch(content);
  final currentVersion = versionMatch != null ? versionMatch.group(1)! : '1.0.0+1';
  
  print('📌 L\'ultima versione inserita/rilasciata è: $currentVersion\n');

  // Calcolo versione consigliata (incremento Patch e Build)
  String suggestedVersion = '';
  try {
    final parts = currentVersion.split('+');
    final semver = parts[0].split('.');
    if (semver.length == 3 && parts.length == 2) {
      final major = int.parse(semver[0]);
      final minor = int.parse(semver[1]);
      final patch = int.parse(semver[2]);
      final build = int.parse(parts[1]);
      suggestedVersion = '$major.$minor.${patch + 1}+${build + 1}';
    }
  } catch (e) {
    // Se c'è un errore di parsing, ignora
  }

  String? newVersion;

  // Se l'utente ha passato il parametro es. "release.bat 1.2.0+8"
  if (args.isNotEmpty) {
    newVersion = args[0].trim();
    print('Hai passato il parametro: $newVersion');
  } else {
    if (suggestedVersion.isNotEmpty) {
      print('💡 Versione consigliata (prossima patch): $suggestedVersion');
      print('Premi INVIO per usare la versione consigliata, oppure digita manualmente la tua (es. 1.2.0+8):');
    } else {
      print('Inserisci la nuova versione (es. 1.2.0+8) oppure scrivi "annulla":');
    }
    
    final input = stdin.readLineSync()?.trim();
    
    if (input != null && input.toLowerCase() == 'annulla') {
      print('Operazione annullata.');
      return;
    }

    if (input == null || input.isEmpty) {
      if (suggestedVersion.isNotEmpty) {
        newVersion = suggestedVersion;
      } else {
        print('Nessuna versione inserita. Operazione annullata.');
        return;
      }
    } else {
      newVersion = input;
    }
  }

  print('\nSto per rilasciare la versione: >>> $newVersion <<<');
  
  // 1. Aggiorna pubspec.yaml
  content = content.replaceFirst(RegExp(r'^version: .*', multiLine: true), 'version: $newVersion');
  await pubspecFile.writeAsString(content);
  print('\n[1/5] pubspec.yaml aggiornato alla versione $newVersion');

  final tagVersion = newVersion.split('+')[0]; // Prende solo '1.1.4' ignorando il '+7'
  final tagName = 'v$tagVersion';

  // Funzione di utilità per eseguire comandi
  Future<void> runCmd(String executable, List<String> arguments, String stepMessage) async {
    print(stepMessage);
    final result = await Process.run(executable, arguments);
    if (result.exitCode != 0) {
      print('ERRORE durante "$executable ${arguments.join(' ')}":');
      print(result.stderr);
      exit(1);
    }
  }

  // 2. Git Add
  await runCmd('git', ['add', '.'], '[2/5] Aggiungo i file modificati (git add .)...');

  // 3. Git Commit
  await runCmd('git', ['commit', '-m', 'Release $tagName'], '[3/5] Creo il commit (git commit)...');

  // 4. Git Push Main
  await runCmd('git', ['push', 'origin', 'main'], '[4/5] Invio il codice su GitHub (git push origin main)...');

  // 5. Git Tag & Push Tag
  await runCmd('git', ['tag', tagName], '[5/5] Creo e invio il Tag $tagName (git tag)...');
  await runCmd('git', ['push', 'origin', tagName], '      Attendere invio del Tag al server...');

  print('\n======================================================');
  print('✅ RILASCIO COMPLETATO CON SUCCESSO!');
  print('Tag $tagName inviato a GitHub.');
  print('La GitHub Action "Build & Release APK" si sta attivando in automatico.');
  print('======================================================\n');
}
