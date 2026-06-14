import 'dart:io';

void main() {
  final dir = Directory('lib');
  final regex = RegExp(r'\.withOpacity\(([^)]+)\)');
  int count = 0;
  
  for (var entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      var content = entity.readAsStringSync();
      if (content.contains('.withOpacity(')) {
        var newContent = content.replaceAllMapped(regex, (match) {
          count++;
          return '.withValues(alpha: ${match.group(1)})';
        });
        if (content != newContent) {
            entity.writeAsStringSync(newContent);
            print('Updated ${entity.path}');
        }
      }
    }
  }
  print('Total replacements: $count');
}
