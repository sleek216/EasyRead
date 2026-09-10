class DictionaryEntry {
  final String word;
  final String pos;
  final String meaning;
  final String example;
  final List<String> synonyms;
  final String origin;
  final String? phonetic;

  DictionaryEntry({
    required this.word,
    required this.pos,
    required this.meaning,
    required this.example,
    required this.synonyms,
    required this.origin,
    this.phonetic,
  });

  factory DictionaryEntry.fromJson(Map<String, dynamic> json) {
    List<String> syns = [];
    if (json['synonyms'] is List) {
      syns = (json['synonyms'] as List).map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    return DictionaryEntry(
      word: json['word']?.toString() ?? '',
      pos: json['pos']?.toString() ?? 'word',
      meaning: json['meaning']?.toString() ?? '',
      example: json['example']?.toString() ?? '',
      synonyms: syns,
      origin: json['origin']?.toString() ?? 'English vocabulary',
      phonetic: json['phonetic']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'pos': pos,
      'meaning': meaning,
      'example': example,
      'synonyms': synonyms,
      'origin': origin,
      'phonetic': phonetic,
    };
  }
}
