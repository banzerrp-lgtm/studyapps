enum QuestionType {
  multipleChoice,
  trueFalse,
  matching,
  fillBlank,
  practicalProblem,
  ordering,
  imageIdentification,
}

enum QuizDifficulty { easy, medium, hard }

class QuizSettings {
  final bool shuffleQuestions;
  final bool showExplanations;
  final bool allowRetry;
  final int timePerQuestionSeconds;
  final bool randomizeOptions;

  const QuizSettings({
    this.shuffleQuestions = false,
    this.showExplanations = true,
    this.allowRetry = true,
    this.timePerQuestionSeconds = 30,
    this.randomizeOptions = false,
  });

  Map<String, dynamic> toJson() => {
    'shuffleQuestions': shuffleQuestions,
    'showExplanations': showExplanations,
    'allowRetry': allowRetry,
    'timePerQuestionSeconds': timePerQuestionSeconds,
    'randomizeOptions': randomizeOptions,
  };

  factory QuizSettings.fromJson(Map<String, dynamic> json) => QuizSettings(
    shuffleQuestions: json['shuffleQuestions'] ?? false,
    showExplanations: json['showExplanations'] ?? true,
    allowRetry: json['allowRetry'] ?? true,
    timePerQuestionSeconds: json['timePerQuestionSeconds'] ?? 30,
    randomizeOptions: json['randomizeOptions'] ?? false,
  );
}

sealed class Question {
  final String id;
  final QuestionType type;
  final String statement;
  final String? imageUrl;
  final String explanation;
  final QuizDifficulty difficulty;
  final int score;

  const Question({
    required this.id,
    required this.type,
    required this.statement,
    this.imageUrl,
    this.explanation = '',
    this.difficulty = QuizDifficulty.medium,
    this.score = 1,
  });

  Map<String, dynamic> toJson();

  factory Question.fromJson(Map<String, dynamic> json) {
    final typeName = json['type']?.toString();
    final type = QuestionType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => QuestionType.multipleChoice,
    );

    switch (type) {
      case QuestionType.multipleChoice:
        return MultipleChoiceQuestion.fromJson(json);
      case QuestionType.trueFalse:
        return TrueFalseQuestion.fromJson(json);
      case QuestionType.matching:
        return MatchingQuestion.fromJson(json);
      case QuestionType.fillBlank:
        return FillBlankQuestion.fromJson(json);
      case QuestionType.practicalProblem:
        return PracticalProblemQuestion.fromJson(json);
      case QuestionType.ordering:
        return OrderingQuestion.fromJson(json);
      case QuestionType.imageIdentification:
        return ImageIdentificationQuestion.fromJson(json);
    }
  }
}

class ChoiceOption {
  final String id;
  final String text;

  const ChoiceOption({required this.id, required this.text});

  Map<String, dynamic> toJson() => {'id': id, 'text': text};

  factory ChoiceOption.fromJson(Map<String, dynamic> json) => ChoiceOption(
    id: json['id']?.toString() ?? '',
    text: json['text']?.toString() ?? '',
  );
}

class MultipleChoiceQuestion extends Question {
  final List<ChoiceOption> options;
  final String correctOptionId;

  const MultipleChoiceQuestion({
    required super.id,
    required super.statement,
    required this.options,
    required this.correctOptionId,
    super.imageUrl,
    super.explanation,
    super.difficulty,
    super.score,
  }) : super(type: QuestionType.multipleChoice);

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'id': id,
    'statement': statement,
    'imageUrl': imageUrl,
    'options': options.map((option) => option.toJson()).toList(),
    'correctOptionId': correctOptionId,
    'explanation': explanation,
    'difficulty': difficulty.name,
    'score': score,
  };

  factory MultipleChoiceQuestion.fromJson(Map<String, dynamic> json) =>
      MultipleChoiceQuestion(
        id: json['id']?.toString() ?? '',
        statement: json['statement']?.toString() ?? '',
        imageUrl: json['imageUrl']?.toString(),
        options: (json['options'] as List? ?? [])
            .map((item) => ChoiceOption.fromJson(item as Map<String, dynamic>))
            .toList(),
        correctOptionId: json['correctOptionId']?.toString() ?? '',
        explanation: json['explanation']?.toString() ?? '',
        difficulty: QuizDifficulty.values.firstWhere(
          (difficulty) => difficulty.name == (json['difficulty'] ?? 'medium'),
          orElse: () => QuizDifficulty.medium,
        ),
        score: int.tryParse(json['score']?.toString() ?? '1') ?? 1,
      );
}

class TrueFalseQuestion extends Question {
  final bool correctAnswer;

  const TrueFalseQuestion({
    required super.id,
    required super.statement,
    required this.correctAnswer,
    super.imageUrl,
    super.explanation,
    super.difficulty,
    super.score,
  }) : super(type: QuestionType.trueFalse);

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'id': id,
    'statement': statement,
    'imageUrl': imageUrl,
    'correctAnswer': correctAnswer,
    'explanation': explanation,
    'difficulty': difficulty.name,
    'score': score,
  };

  factory TrueFalseQuestion.fromJson(Map<String, dynamic> json) =>
      TrueFalseQuestion(
        id: json['id']?.toString() ?? '',
        statement: json['statement']?.toString() ?? '',
        imageUrl: json['imageUrl']?.toString(),
        correctAnswer: json['correctAnswer'] ?? true,
        explanation: json['explanation']?.toString() ?? '',
        difficulty: QuizDifficulty.values.firstWhere(
          (difficulty) => difficulty.name == (json['difficulty'] ?? 'medium'),
          orElse: () => QuizDifficulty.medium,
        ),
        score: int.tryParse(json['score']?.toString() ?? '1') ?? 1,
      );
}

class MatchingPair {
  final String left;
  final String right;

  const MatchingPair({required this.left, required this.right});

  Map<String, dynamic> toJson() => {'left': left, 'right': right};

  factory MatchingPair.fromJson(Map<String, dynamic> json) => MatchingPair(
    left: json['left']?.toString() ?? '',
    right: json['right']?.toString() ?? '',
  );
}

class MatchingQuestion extends Question {
  final List<MatchingPair> pairs;
  final List<String> leftColumn;
  final List<String> rightColumn;

  const MatchingQuestion({
    required super.id,
    required super.statement,
    required this.pairs,
    required this.leftColumn,
    required this.rightColumn,
    super.imageUrl,
    super.explanation,
    super.difficulty,
    super.score,
  }) : super(type: QuestionType.matching);

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'id': id,
    'statement': statement,
    'imageUrl': imageUrl,
    'pairs': pairs.map((pair) => pair.toJson()).toList(),
    'leftColumn': leftColumn,
    'rightColumn': rightColumn,
    'explanation': explanation,
    'difficulty': difficulty.name,
    'score': score,
  };

  factory MatchingQuestion.fromJson(Map<String, dynamic> json) =>
      MatchingQuestion(
        id: json['id']?.toString() ?? '',
        statement: json['statement']?.toString() ?? '',
        imageUrl: json['imageUrl']?.toString(),
        pairs: (json['pairs'] as List? ?? [])
            .map((item) => MatchingPair.fromJson(item as Map<String, dynamic>))
            .toList(),
        leftColumn: List<String>.from(json['leftColumn'] ?? const []),
        rightColumn: List<String>.from(json['rightColumn'] ?? const []),
        explanation: json['explanation']?.toString() ?? '',
        difficulty: QuizDifficulty.values.firstWhere(
          (difficulty) => difficulty.name == (json['difficulty'] ?? 'medium'),
          orElse: () => QuizDifficulty.medium,
        ),
        score: int.tryParse(json['score']?.toString() ?? '1') ?? 1,
      );
}

class FillBlankAnswer {
  final String id;
  final String expectedAnswer;
  final String? hint;

  const FillBlankAnswer({
    required this.id,
    required this.expectedAnswer,
    this.hint,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'expectedAnswer': expectedAnswer,
    'hint': hint,
  };

  factory FillBlankAnswer.fromJson(Map<String, dynamic> json) =>
      FillBlankAnswer(
        id: json['id']?.toString() ?? '',
        expectedAnswer: json['expectedAnswer']?.toString() ?? '',
        hint: json['hint']?.toString(),
      );
}

class FillBlankQuestion extends Question {
  final List<FillBlankAnswer> blanks;

  const FillBlankQuestion({
    required super.id,
    required super.statement,
    required this.blanks,
    super.imageUrl,
    super.explanation,
    super.difficulty,
    super.score,
  }) : super(type: QuestionType.fillBlank);

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'id': id,
    'statement': statement,
    'imageUrl': imageUrl,
    'blanks': blanks.map((blank) => blank.toJson()).toList(),
    'explanation': explanation,
    'difficulty': difficulty.name,
    'score': score,
  };

  factory FillBlankQuestion.fromJson(Map<String, dynamic> json) =>
      FillBlankQuestion(
        id: json['id']?.toString() ?? '',
        statement: json['statement']?.toString() ?? '',
        imageUrl: json['imageUrl']?.toString(),
        blanks: (json['blanks'] as List? ?? [])
            .map(
              (item) => FillBlankAnswer.fromJson(item as Map<String, dynamic>),
            )
            .toList(),
        explanation: json['explanation']?.toString() ?? '',
        difficulty: QuizDifficulty.values.firstWhere(
          (difficulty) => difficulty.name == (json['difficulty'] ?? 'medium'),
          orElse: () => QuizDifficulty.medium,
        ),
        score: int.tryParse(json['score']?.toString() ?? '1') ?? 1,
      );
}

class PracticalProblemQuestion extends Question {
  final String problemText;
  final String expectedSolution;
  final List<String> steps;

  const PracticalProblemQuestion({
    required super.id,
    required super.statement,
    required this.problemText,
    required this.expectedSolution,
    this.steps = const [],
    super.imageUrl,
    super.explanation,
    super.difficulty,
    super.score,
  }) : super(type: QuestionType.practicalProblem);

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'id': id,
    'statement': statement,
    'imageUrl': imageUrl,
    'problemText': problemText,
    'expectedSolution': expectedSolution,
    'steps': steps,
    'explanation': explanation,
    'difficulty': difficulty.name,
    'score': score,
  };

  factory PracticalProblemQuestion.fromJson(Map<String, dynamic> json) =>
      PracticalProblemQuestion(
        id: json['id']?.toString() ?? '',
        statement: json['statement']?.toString() ?? '',
        imageUrl: json['imageUrl']?.toString(),
        problemText: json['problemText']?.toString() ?? '',
        expectedSolution: json['expectedSolution']?.toString() ?? '',
        steps: List<String>.from(json['steps'] ?? const []),
        explanation: json['explanation']?.toString() ?? '',
        difficulty: QuizDifficulty.values.firstWhere(
          (difficulty) => difficulty.name == (json['difficulty'] ?? 'medium'),
          orElse: () => QuizDifficulty.medium,
        ),
        score: int.tryParse(json['score']?.toString() ?? '1') ?? 1,
      );
}

class OrderingQuestion extends Question {
  final List<String> items;
  final List<String> correctOrder;

  const OrderingQuestion({
    required super.id,
    required super.statement,
    required this.items,
    required this.correctOrder,
    super.imageUrl,
    super.explanation,
    super.difficulty,
    super.score,
  }) : super(type: QuestionType.ordering);

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'id': id,
    'statement': statement,
    'imageUrl': imageUrl,
    'items': items,
    'correctOrder': correctOrder,
    'explanation': explanation,
    'difficulty': difficulty.name,
    'score': score,
  };

  factory OrderingQuestion.fromJson(Map<String, dynamic> json) =>
      OrderingQuestion(
        id: json['id']?.toString() ?? '',
        statement: json['statement']?.toString() ?? '',
        imageUrl: json['imageUrl']?.toString(),
        items: List<String>.from(json['items'] ?? const []),
        correctOrder: List<String>.from(json['correctOrder'] ?? const []),
        explanation: json['explanation']?.toString() ?? '',
        difficulty: QuizDifficulty.values.firstWhere(
          (difficulty) => difficulty.name == (json['difficulty'] ?? 'medium'),
          orElse: () => QuizDifficulty.medium,
        ),
        score: int.tryParse(json['score']?.toString() ?? '1') ?? 1,
      );
}

class ImageIdentificationQuestion extends Question {
  final String imageUrlQuestion;
  final List<ChoiceOption> options;
  final String correctOptionId;

  const ImageIdentificationQuestion({
    required super.id,
    required super.statement,
    required this.imageUrlQuestion,
    required this.options,
    required this.correctOptionId,
    super.explanation,
    super.difficulty,
    super.score,
  }) : super(
         type: QuestionType.imageIdentification,
         imageUrl: imageUrlQuestion,
       );

  @override
  Map<String, dynamic> toJson() => {
    'type': type.name,
    'id': id,
    'statement': statement,
    'imageUrl': imageUrlQuestion,
    'options': options.map((option) => option.toJson()).toList(),
    'correctOptionId': correctOptionId,
    'explanation': explanation,
    'difficulty': difficulty.name,
    'score': score,
  };

  factory ImageIdentificationQuestion.fromJson(Map<String, dynamic> json) =>
      ImageIdentificationQuestion(
        id: json['id']?.toString() ?? '',
        statement: json['statement']?.toString() ?? '',
        imageUrlQuestion: json['imageUrl']?.toString() ?? '',
        options: (json['options'] as List? ?? [])
            .map((item) => ChoiceOption.fromJson(item as Map<String, dynamic>))
            .toList(),
        correctOptionId: json['correctOptionId']?.toString() ?? '',
        explanation: json['explanation']?.toString() ?? '',
        difficulty: QuizDifficulty.values.firstWhere(
          (difficulty) => difficulty.name == (json['difficulty'] ?? 'medium'),
          orElse: () => QuizDifficulty.medium,
        ),
        score: int.tryParse(json['score']?.toString() ?? '1') ?? 1,
      );
}

class Quiz {
  final String id;
  final String subject;
  final String title;
  final String description;
  final List<Question> questions;
  final QuizSettings settings;

  const Quiz({
    required this.id,
    required this.subject,
    required this.title,
    required this.description,
    required this.questions,
    this.settings = const QuizSettings(),
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject': subject,
    'title': title,
    'description': description,
    'questions': questions.map((question) => question.toJson()).toList(),
    'settings': settings.toJson(),
  };

  factory Quiz.fromJson(Map<String, dynamic> json) => Quiz(
    id: json['id']?.toString() ?? '',
    subject: json['subject']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    description: json['description']?.toString() ?? '',
    questions: (json['questions'] as List? ?? [])
        .map((item) => Question.fromJson(item as Map<String, dynamic>))
        .toList(),
    settings: QuizSettings.fromJson(
      json['settings'] as Map<String, dynamic>? ?? {},
    ),
  );
}

class QuizDraft {
  String title = '';
  String subject = '';
  String description = '';
  final List<QuestionType> selectedTypes = <QuestionType>[];
  final Map<QuestionType, int> questionCounts = <QuestionType, int>{};
  final List<Question> questions = <Question>[];

  void configure({
    required String title,
    required String subject,
    required String description,
    required List<QuestionType> types,
    required Map<QuestionType, int> counts,
  }) {
    this.title = title.trim();
    this.subject = subject.trim();
    this.description = description.trim();
    selectedTypes
      ..clear()
      ..addAll(types);

    questionCounts
      ..clear()
      ..addAll(counts);

    generateQuestions();
  }

  void generateQuestions() {
    questions.clear();
    for (final type in selectedTypes) {
      final count = (questionCounts[type] ?? 1).clamp(1, 10);
      for (var i = 0; i < count; i++) {
        questions.add(createEmptyQuestion(type));
      }
    }
  }

  void addQuestion(QuestionType type) {
    questions.add(createEmptyQuestion(type));
  }

  void removeQuestion(int index) {
    if (index < 0 || index >= questions.length) return;
    questions.removeAt(index);
  }

  void duplicateQuestion(int index) {
    if (index < 0 || index >= questions.length) return;
    final clone = cloneQuestion(questions[index]);
    questions.insert(index + 1, clone);
  }

  void moveQuestion(int from, int to) {
    if (from < 0 || from >= questions.length) return;
    final target = to.clamp(0, questions.length - 1);
    final question = questions.removeAt(from);
    questions.insert(target, question);
  }

  Quiz buildQuiz({String id = ''}) {
    return Quiz(
      id: id.isEmpty ? DateTime.now().microsecondsSinceEpoch.toString() : id,
      subject: subject,
      title: title.isEmpty ? 'Sin título' : title,
      description: description,
      questions: List<Question>.from(questions),
      settings: const QuizSettings(),
    );
  }

  static Question createEmptyQuestion(QuestionType type) {
    final id = 'q_${DateTime.now().millisecondsSinceEpoch}_${type.name}';

    switch (type) {
      case QuestionType.multipleChoice:
        return MultipleChoiceQuestion(
          id: id,
          statement: '',
          options: const [
            ChoiceOption(id: 'a', text: ''),
            ChoiceOption(id: 'b', text: ''),
            ChoiceOption(id: 'c', text: ''),
            ChoiceOption(id: 'd', text: ''),
          ],
          correctOptionId: 'a',
        );
      case QuestionType.trueFalse:
        return TrueFalseQuestion(id: id, statement: '', correctAnswer: true);
      case QuestionType.matching:
        return MatchingQuestion(
          id: id,
          statement: '',
          pairs: const [MatchingPair(left: '', right: '')],
          leftColumn: const [''],
          rightColumn: const [''],
        );
      case QuestionType.fillBlank:
        return FillBlankQuestion(
          id: id,
          statement: '',
          blanks: const [FillBlankAnswer(id: 'blank_1', expectedAnswer: '')],
        );
      case QuestionType.practicalProblem:
        return PracticalProblemQuestion(
          id: id,
          statement: '',
          problemText: '',
          expectedSolution: '',
          steps: const [],
        );
      case QuestionType.ordering:
        return OrderingQuestion(
          id: id,
          statement: '',
          items: const [''],
          correctOrder: const [''],
        );
      case QuestionType.imageIdentification:
        return ImageIdentificationQuestion(
          id: id,
          statement: '',
          imageUrlQuestion: '',
          options: const [
            ChoiceOption(id: 'a', text: ''),
            ChoiceOption(id: 'b', text: ''),
            ChoiceOption(id: 'c', text: ''),
            ChoiceOption(id: 'd', text: ''),
          ],
          correctOptionId: 'a',
        );
    }
  }

  static Question cloneQuestion(Question question) {
    switch (question) {
      case MultipleChoiceQuestion q:
        return MultipleChoiceQuestion(
          id: '${q.id}_copy',
          statement: q.statement,
          options: List<ChoiceOption>.from(q.options),
          correctOptionId: q.correctOptionId,
          imageUrl: q.imageUrl,
          explanation: q.explanation,
          difficulty: q.difficulty,
          score: q.score,
        );
      case TrueFalseQuestion q:
        return TrueFalseQuestion(
          id: '${q.id}_copy',
          statement: q.statement,
          correctAnswer: q.correctAnswer,
          imageUrl: q.imageUrl,
          explanation: q.explanation,
          difficulty: q.difficulty,
          score: q.score,
        );
      case MatchingQuestion q:
        return MatchingQuestion(
          id: '${q.id}_copy',
          statement: q.statement,
          pairs: List<MatchingPair>.from(q.pairs),
          leftColumn: List<String>.from(q.leftColumn),
          rightColumn: List<String>.from(q.rightColumn),
          imageUrl: q.imageUrl,
          explanation: q.explanation,
          difficulty: q.difficulty,
          score: q.score,
        );
      case FillBlankQuestion q:
        return FillBlankQuestion(
          id: '${q.id}_copy',
          statement: q.statement,
          blanks: List<FillBlankAnswer>.from(q.blanks),
          imageUrl: q.imageUrl,
          explanation: q.explanation,
          difficulty: q.difficulty,
          score: q.score,
        );
      case PracticalProblemQuestion q:
        return PracticalProblemQuestion(
          id: '${q.id}_copy',
          statement: q.statement,
          problemText: q.problemText,
          expectedSolution: q.expectedSolution,
          steps: List<String>.from(q.steps),
          imageUrl: q.imageUrl,
          explanation: q.explanation,
          difficulty: q.difficulty,
          score: q.score,
        );
      case OrderingQuestion q:
        return OrderingQuestion(
          id: '${q.id}_copy',
          statement: q.statement,
          items: List<String>.from(q.items),
          correctOrder: List<String>.from(q.correctOrder),
          imageUrl: q.imageUrl,
          explanation: q.explanation,
          difficulty: q.difficulty,
          score: q.score,
        );
      case ImageIdentificationQuestion q:
        return ImageIdentificationQuestion(
          id: '${q.id}_copy',
          statement: q.statement,
          imageUrlQuestion: q.imageUrlQuestion,
          options: List<ChoiceOption>.from(q.options),
          correctOptionId: q.correctOptionId,
          explanation: q.explanation,
          difficulty: q.difficulty,
          score: q.score,
        );
    }
  }
}
