// Regenerates bilingual repo docs (docs/DEPENDENCIES.md, docs/STRUCTURE.md,
// docs/SCREENS.md) from the actual code. Run: dart run tool/generate_docs.dart
import 'dart:io';

Future<void> main() async {
  final docs = Directory('${Directory.current.path}${Platform.pathSeparator}docs');
  if (!docs.existsSync()) {
    docs.createSync(recursive: true);
  }
  await File('${docs.path}${Platform.pathSeparator}DEPENDENCIES.md').writeAsString(await _dependencies());
  await File('${docs.path}${Platform.pathSeparator}STRUCTURE.md').writeAsString(_structure());
  await File('${docs.path}${Platform.pathSeparator}SCREENS.md').writeAsString(_screens());
  stdout.writeln('Docs regenerated → docs/ (DEPENDENCIES.md, STRUCTURE.md, SCREENS.md)');
}

Future<String> _dependencies() async {
  final text = await File('${Directory.current.path}${Platform.pathSeparator}pubspec.yaml').readAsString();
  final lines = text.split('\n');
  final main = <String>[];
  final dev = <String>[];
  bool inDeps = false, inDev = false;
  final re = RegExp(r'^  ([a-zA-Z0-9_]+):\s*(.*)$');
  for (final raw in lines) {
    final line = raw.trimRight();
    if (line.startsWith('dependencies:')) {
      inDeps = true;
      inDev = false;
      continue;
    }
    if (line.startsWith('dev_dependencies:')) {
      inDev = true;
      inDeps = false;
      continue;
    }
    if (line.isEmpty) {
      inDeps = false;
      inDev = false;
      continue;
    }
    if (!line.startsWith('  ')) {
      inDeps = false;
      inDev = false;
      continue;
    }
    final m = re.firstMatch(line);
    if (m == null) {
      continue;
    }
    final name = m.group(1)!;
    var ver = m.group(2)!.trim();
    if (ver.isEmpty) {
      ver = '(block/sdk)';
    }
    (inDev ? dev : main).add('| `$name` | `$ver` |');
  }
  final buf = StringBuffer()
    ..writeln('# الاعتماديات — Dependencies')
    ..writeln()
    ..writeln('> تُولَّد تلقائياً من `pubspec.yaml` — Generated from `pubspec.yaml`.')
    ..writeln()
    ..writeln('## رئيسية — Main')
    ..writeln('| Package | Version |')
    ..writeln('|---|---|');
  buf.writeln(main.join('\n'));
  if (dev.isNotEmpty) {
    buf
      ..writeln()
      ..writeln('## تطويرية — Dev')
      ..writeln('| Package | Version |')
      ..writeln('|---|---|')
      ..writeln(dev.join('\n'));
  }
  buf
    ..writeln()
    ..writeln('---')
    ..writeln('*لا تعدّل هذا الملف يدوياً — أعد توليده (Do not edit by hand).*');
  return buf.toString();
}

String _structure() {
  final buf = StringBuffer()
    ..writeln('# بنية الكود — Code Structure')
    ..writeln()
    ..writeln('> تُولَّد من `lib/` — Generated from `lib/`.')
    ..writeln()
    ..writeln('```');
  final root = Directory('${Directory.current.path}${Platform.pathSeparator}lib');
  if (root.existsSync()) {
    _tree(root, '', buf);
  }
  buf
    ..writeln('```')
    ..writeln()
    ..writeln('---')
    ..writeln('*لا تعدّل هذا الملف يدوياً — أعد توليده (Do not edit by hand).*');
  return buf.toString();
}

void _tree(Directory dir, String indent, StringBuffer buf) {
  final entries = dir.listSync().whereType<FileSystemEntity>().toList()
    ..sort((a, b) {
      final da = a is Directory ? 0 : 1;
      final db = b is Directory ? 0 : 1;
      return da != db ? da - db : a.path.compareTo(b.path);
    });
  for (final e in entries) {
    final name = e.path.split(Platform.pathSeparator).last;
    buf.writeln('$indent${e is Directory ? '📁 ' : '📄 '}$name');
    if (e is Directory) {
      _tree(e, '$indent    ', buf);
    }
  }
}

String _screens() {
  final buf = StringBuffer()
    ..writeln('# الشاشات — Screens')
    ..writeln()
    ..writeln('> تُولَّد من ملفات `*Screen*.dart` — Generated from screen widgets.')
    ..writeln()
    ..writeln('| الشاشة — Screen | المسار — Path |')
    ..writeln('|---|---|');
  final root = Directory('${Directory.current.path}${Platform.pathSeparator}lib');
  if (root.existsSync()) {
    for (final f in root.listSync(recursive: true).whereType<File>()) {
      final name = f.path.split(Platform.pathSeparator).last;
      if (name.toLowerCase().contains('screen') && name.endsWith('.dart')) {
        final rel = f.path.replaceAll(Directory.current.path + Platform.pathSeparator, '');
        buf.writeln('| `$name` | `$rel` |');
      }
    }
  }
  buf
    ..writeln()
    ..writeln('---')
    ..writeln('*لا تعدّل هذا الملف يدوياً — أعد توليده (Do not edit by hand).*');
  return buf.toString();
}
