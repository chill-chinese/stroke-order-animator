// ignore_for_file: avoid_print

import 'dart:io';

const types = {
  'feat': '🚀 Features',
  'fix': '🐛 Bugfixes',
  'perf': '⚡️ Performance Improvements',
  'docs': '📝 Documentation',
  'test': '✅ Tests',
  'ci': '🔄 Continuous Integration',
  'build': ' 🏗️ Build System / Dependencies',
  'refactor': '🔧 Code Refactoring',
  'tool': '🧰 Tooling',
  'chore': '🤷 Others',
};

Future<void> main(List<String> arguments) async {
  if (arguments.length != 1) {
    print(
      'Usage: dart run tool/changelog_generator.dart <lastVersion>',
    );
    exit(1);
  }

  final oldVersion = arguments[0];

  // Get the list of commits from git
  final result = await Process.run(
    'git',
    ['log', '--pretty=format:"%s"', '$oldVersion..HEAD'],
  );

  final categorizedCommits =
      processCommits((result.stdout as String).split('\n'));

  final String changelogContent = generateMarkdownChangelog(categorizedCommits);

  const outputFile = '_CHANGELOG.md';
  File(outputFile).writeAsStringSync(changelogContent);
  print('Changelog written to $outputFile');
}

Map<String, List<String>> processCommits(List<String> commitMessages) {
  final Map<String, List<String>> categorizedCommits = {};

  for (var commitMessage in commitMessages) {
    // Remove leading and trailing quotation marks
    commitMessage = commitMessage.replaceAll(RegExp('^"'), '');
    commitMessage = commitMessage.replaceAll(RegExp('"\$'), '');

    if (!types.keys.any((t) => commitMessage.startsWith(t))) {
      print("Failed to categorize line: '$commitMessage'");
    }

    for (final type in types.keys) {
      if (commitMessage.startsWith('$type:')) {
        categorizedCommits
            .putIfAbsent(type, () => [])
            .add(commitMessage.replaceFirst(RegExp('$type:\\s*'), ''));
        break;
      }
    }
  }

  return categorizedCommits;
}

String generateMarkdownChangelog(Map<String, List<String>> commits) {
  final buffer = StringBuffer();
  for (final type in types.keys) {
    if (commits.containsKey(type)) {
      buffer.writeln('## ${types[type]}\n');
      final messages = commits[type]!;

      for (final message in messages) {
        buffer.writeln('- $message');
      }

      buffer.writeln();
    }
  }

  return buffer.toString();
}
