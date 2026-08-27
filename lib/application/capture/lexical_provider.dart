final class LexicalSense {
  const LexicalSense({required this.partOfSpeech, required this.definition});

  final String partOfSpeech;
  final String definition;
}

final class LexicalLookup {
  const LexicalLookup({required this.term, required this.senses});

  final String term;
  final List<LexicalSense> senses;
}

abstract interface class LexicalProvider {
  String get attribution;

  Future<LexicalLookup> lookup(String term);
}

final class LexicalLookupException implements Exception {
  const LexicalLookupException(this.message);

  final String message;

  @override
  String toString() => message;
}
