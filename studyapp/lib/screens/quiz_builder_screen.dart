import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/quiz.dart';
import '../providers/subjects_provider.dart';
import '../services/database_service.dart';

class QuizBuilderScreen extends StatefulWidget {
  const QuizBuilderScreen({super.key});

  @override
  State<QuizBuilderScreen> createState() => _QuizBuilderScreenState();
}

class _QuizBuilderScreenState extends State<QuizBuilderScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final QuizDraft _draft = QuizDraft();
  bool _showConfig = true;
  int _currentQuestionIndex = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _applyConfig() {
    final selectedTypes = _draft.selectedTypes.toList();
    final counts = <QuestionType, int>{};

    for (final type in QuestionType.values) {
      final value = _typeCount(type);
      if (value > 0) {
        counts[type] = value;
      }
    }

    if (selectedTypes.isEmpty || counts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Selecciona al menos un tipo de pregunta y una cantidad.',
          ),
        ),
      );
      return;
    }

    _draft.configure(
      title: _titleController.text,
      subject: _subjectController.text,
      description: _descriptionController.text,
      types: selectedTypes,
      counts: counts,
    );

    setState(() {
      _showConfig = false;
      _currentQuestionIndex = 0;
    });
  }

  int _typeCount(QuestionType type) {
    return (_draft.questionCounts[type] ?? 0).clamp(1, 10);
  }

  void _toggleType(QuestionType type) {
    final selected = _draft.selectedTypes.contains(type);
    if (selected) {
      _draft.selectedTypes.remove(type);
      _draft.questionCounts.remove(type);
    } else {
      _draft.selectedTypes.add(type);
      _draft.questionCounts[type] = 1;
    }
    setState(() {});
  }

  void _changeTypeCount(QuestionType type, int delta) {
    final current = _draft.questionCounts[type] ?? 1;
    final next = (current + delta).clamp(1, 10);
    _draft.questionCounts[type] = next;
    setState(() {});
  }

  void _updateQuestion(Question updatedQuestion) {
    if (_draft.questions.isEmpty) return;
    setState(() {
      _draft.questions[_currentQuestionIndex] = updatedQuestion;
    });
  }

  void _save() {
    final quiz = _draft.buildQuiz();

    if (quiz.subject.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una materia válida.')),
      );
      return;
    }

    DatabaseService.instance.saveQuiz(quiz);
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context, quiz);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quiz guardado correctamente.')),
    );
  }

  void _addQuestion() {
    if (_draft.selectedTypes.isEmpty) return;
    final type = _draft.selectedTypes.first;
    _draft.addQuestion(type);
    setState(() {
      _currentQuestionIndex = _draft.questions.length - 1;
    });
  }

  void _duplicateQuestion() {
    if (_draft.questions.isEmpty) return;
    _draft.duplicateQuestion(_currentQuestionIndex);
    setState(() {
      _currentQuestionIndex = _currentQuestionIndex + 1;
    });
  }

  void _deleteQuestion() {
    if (_draft.questions.isEmpty) return;
    _draft.removeQuestion(_currentQuestionIndex);
    if (_draft.questions.isEmpty) {
      setState(() {
        _currentQuestionIndex = 0;
      });
      return;
    }
    setState(() {
      if (_currentQuestionIndex >= _draft.questions.length) {
        _currentQuestionIndex = _draft.questions.length - 1;
      }
    });
  }

  void _moveQuestion(int delta) {
    if (_draft.questions.isEmpty) return;
    final target = _currentQuestionIndex + delta;
    if (target < 0 || target >= _draft.questions.length) return;
    _draft.moveQuestion(_currentQuestionIndex, target);
    setState(() {
      _currentQuestionIndex = target;
    });
  }

  Widget _buildQuestionTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: QuestionType.values.map((type) {
        final selected = _draft.selectedTypes.contains(type);
        return ChoiceChip(
          label: Text(_questionTypeLabel(type)),
          selected: selected,
          onSelected: (_) => _toggleType(type),
          avatar: selected ? const Icon(Icons.check, size: 14) : null,
        );
      }).toList(),
    );
  }

  Widget _buildCountEditor() {
    final selectedTypes = _draft.selectedTypes;
    if (selectedTypes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text(
          'Cantidad por tipo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...selectedTypes.map((type) {
          final count = _draft.questionCounts[type] ?? 1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: Text(_questionTypeLabel(type))),
                IconButton(
                  onPressed: () => _changeTypeCount(type, -1),
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(width: 36, child: Center(child: Text('$count'))),
                IconButton(
                  onPressed: () => _changeTypeCount(type, 1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<SubjectsProvider>().subjects;

    if (_showConfig) {
      final selectedSubject = _subjectController.text.trim();
      final subjectValue = subjects.contains(selectedSubject)
          ? selectedSubject
          : (subjects.isNotEmpty ? subjects.first : null);

      if (subjectValue != null && _subjectController.text.trim().isEmpty) {
        _subjectController.text = subjectValue;
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text('Nuevo quiz'),
          actions: [
            TextButton.icon(
              onPressed: _applyConfig,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Siguiente'),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Título',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (subjects.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Primero crea al menos una materia en la sección de Materias.',
                    ),
                  )
                else
                  DropdownButtonFormField<String>(
                    value: subjectValue,
                    decoration: const InputDecoration(
                      labelText: 'Materia',
                      border: OutlineInputBorder(),
                    ),
                    items: subjects
                        .map(
                          (subject) => DropdownMenuItem(
                            value: subject,
                            child: Text(subject),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      _subjectController.text = value;
                    },
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Tipos de preguntas',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                _buildQuestionTypeSelector(),
                _buildCountEditor(),
              ],
            ),
          ),
        ),
      );
    }

    final questions = _draft.questions;
    if (_currentQuestionIndex >= questions.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _currentQuestionIndex = questions.length - 1;
        });
      });
    }

    final currentQuestion = questions.isEmpty
        ? null
        : questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(_draft.title.isEmpty ? 'Editar quiz' : _draft.title),
        actions: [
          IconButton(
            tooltip: 'Guardar quiz',
            onPressed: _save,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_draft.subject.isEmpty ? 'Materia' : _draft.subject} • ${questions.length} preguntas',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _draft.description.isEmpty
                          ? 'Sin descripción'
                          : _draft.description,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pregunta ${_currentQuestionIndex + 1} de ${questions.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    onPressed: _currentQuestionIndex > 0
                        ? () => _moveQuestion(-1)
                        : null,
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  IconButton(
                    onPressed: _currentQuestionIndex < questions.length - 1
                        ? () => _moveQuestion(1)
                        : null,
                    icon: const Icon(Icons.arrow_downward),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (currentQuestion != null) ...[
                Expanded(
                  child: SingleChildScrollView(
                    child: QuestionEditor(
                      question: currentQuestion,
                      onChanged: _updateQuestion,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _duplicateQuestion,
                        icon: const Icon(Icons.copy),
                        label: const Text('Duplicar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _deleteQuestion,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Eliminar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add),
                    label: const Text('Agregar pregunta'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _questionTypeLabel(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Opción múltiple';
      case QuestionType.trueFalse:
        return 'Verdadero/Falso';
      case QuestionType.matching:
        return 'Emparejamiento';
      case QuestionType.fillBlank:
        return 'Rellenar huecos';
      case QuestionType.practicalProblem:
        return 'Problema práctico';
      case QuestionType.ordering:
        return 'Ordenación';
      case QuestionType.imageIdentification:
        return 'Identificación visual';
    }
  }
}

class QuestionEditor extends StatefulWidget {
  final Question question;
  final ValueChanged<Question> onChanged;

  const QuestionEditor({
    super.key,
    required this.question,
    required this.onChanged,
  });

  @override
  State<QuestionEditor> createState() => _QuestionEditorState();
}

class _QuestionEditorState extends State<QuestionEditor> {
  late final TextEditingController _statementController;
  late final TextEditingController _explanationController;
  late final TextEditingController _scoreController;

  @override
  void initState() {
    super.initState();
    _statementController = TextEditingController(
      text: widget.question.statement,
    );
    _explanationController = TextEditingController(
      text: widget.question.explanation,
    );
    _scoreController = TextEditingController(
      text: widget.question.score.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant QuestionEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      _statementController.text = widget.question.statement;
      _explanationController.text = widget.question.explanation;
      _scoreController.text = widget.question.score.toString();
    }
  }

  @override
  void dispose() {
    _statementController.dispose();
    _explanationController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  Question _updatedQuestion({
    String? statement,
    String? explanation,
    QuizDifficulty? difficulty,
    int? score,
    bool? correctAnswer,
    String? correctOptionId,
    List<ChoiceOption>? options,
    List<MatchingPair>? pairs,
    List<String>? leftColumn,
    List<String>? rightColumn,
    List<FillBlankAnswer>? blanks,
    String? problemText,
    String? expectedSolution,
    List<String>? steps,
    List<String>? items,
    List<String>? correctOrder,
    String? imageUrlQuestion,
  }) {
    switch (widget.question) {
      case MultipleChoiceQuestion q:
        return MultipleChoiceQuestion(
          id: q.id,
          statement: statement ?? q.statement,
          options: options ?? q.options,
          correctOptionId: correctOptionId ?? q.correctOptionId,
          imageUrl: q.imageUrl,
          explanation: explanation ?? q.explanation,
          difficulty: difficulty ?? q.difficulty,
          score: score ?? q.score,
        );
      case TrueFalseQuestion q:
        return TrueFalseQuestion(
          id: q.id,
          statement: statement ?? q.statement,
          correctAnswer: correctAnswer ?? q.correctAnswer,
          imageUrl: q.imageUrl,
          explanation: explanation ?? q.explanation,
          difficulty: difficulty ?? q.difficulty,
          score: score ?? q.score,
        );
      case MatchingQuestion q:
        return MatchingQuestion(
          id: q.id,
          statement: statement ?? q.statement,
          pairs: pairs ?? q.pairs,
          leftColumn: leftColumn ?? q.leftColumn,
          rightColumn: rightColumn ?? q.rightColumn,
          imageUrl: q.imageUrl,
          explanation: explanation ?? q.explanation,
          difficulty: difficulty ?? q.difficulty,
          score: score ?? q.score,
        );
      case FillBlankQuestion q:
        return FillBlankQuestion(
          id: q.id,
          statement: statement ?? q.statement,
          blanks: blanks ?? q.blanks,
          imageUrl: q.imageUrl,
          explanation: explanation ?? q.explanation,
          difficulty: difficulty ?? q.difficulty,
          score: score ?? q.score,
        );
      case PracticalProblemQuestion q:
        return PracticalProblemQuestion(
          id: q.id,
          statement: statement ?? q.statement,
          problemText: problemText ?? q.problemText,
          expectedSolution: expectedSolution ?? q.expectedSolution,
          steps: steps ?? q.steps,
          imageUrl: q.imageUrl,
          explanation: explanation ?? q.explanation,
          difficulty: difficulty ?? q.difficulty,
          score: score ?? q.score,
        );
      case OrderingQuestion q:
        return OrderingQuestion(
          id: q.id,
          statement: statement ?? q.statement,
          items: items ?? q.items,
          correctOrder: correctOrder ?? q.correctOrder,
          imageUrl: q.imageUrl,
          explanation: explanation ?? q.explanation,
          difficulty: difficulty ?? q.difficulty,
          score: score ?? q.score,
        );
      case ImageIdentificationQuestion q:
        return ImageIdentificationQuestion(
          id: q.id,
          statement: statement ?? q.statement,
          imageUrlQuestion: imageUrlQuestion ?? q.imageUrlQuestion,
          options: options ?? q.options,
          correctOptionId: correctOptionId ?? q.correctOptionId,
          explanation: explanation ?? q.explanation,
          difficulty: difficulty ?? q.difficulty,
          score: score ?? q.score,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _typeName(widget.question.type),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _statementController,
              decoration: const InputDecoration(
                labelText: 'Enunciado',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
              onChanged: (value) {
                widget.onChanged(_updatedQuestion(statement: value));
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _explanationController,
              decoration: const InputDecoration(
                labelText: 'Explicación',
                border: OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 3,
              onChanged: (value) {
                widget.onChanged(_updatedQuestion(explanation: value));
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<QuizDifficulty>(
                    initialValue: widget.question.difficulty,
                    decoration: const InputDecoration(
                      labelText: 'Dificultad',
                      border: OutlineInputBorder(),
                    ),
                    items: QuizDifficulty.values.map((difficulty) {
                      return DropdownMenuItem(
                        value: difficulty,
                        child: Text(_difficultyLabel(difficulty)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      widget.onChanged(_updatedQuestion(difficulty: value));
                    },
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: TextField(
                    controller: _scoreController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Puntuación',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value) ?? 1;
                      widget.onChanged(_updatedQuestion(score: parsed));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSpecificEditor(),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificEditor() {
    switch (widget.question) {
      case MultipleChoiceQuestion q:
        return _MultipleChoiceEditor(
          question: q,
          onChanged: (updated) => widget.onChanged(updated),
        );
      case TrueFalseQuestion q:
        return _TrueFalseEditor(
          question: q,
          onChanged: (updated) => widget.onChanged(updated),
        );
      case MatchingQuestion q:
        return _MatchingEditor(
          question: q,
          onChanged: (updated) => widget.onChanged(updated),
        );
      case FillBlankQuestion q:
        return _FillBlankEditor(
          question: q,
          onChanged: (updated) => widget.onChanged(updated),
        );
      case PracticalProblemQuestion q:
        return _PracticalProblemEditor(
          question: q,
          onChanged: (updated) => widget.onChanged(updated),
        );
      case OrderingQuestion q:
        return _OrderingEditor(
          question: q,
          onChanged: (updated) => widget.onChanged(updated),
        );
      case ImageIdentificationQuestion q:
        return _ImageIdentificationEditor(
          question: q,
          onChanged: (updated) => widget.onChanged(updated),
        );
    }
  }

  String _typeName(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Opción múltiple';
      case QuestionType.trueFalse:
        return 'Verdadero o falso';
      case QuestionType.matching:
        return 'Emparejamiento';
      case QuestionType.fillBlank:
        return 'Completar huecos';
      case QuestionType.practicalProblem:
        return 'Problema práctico';
      case QuestionType.ordering:
        return 'Ordenación';
      case QuestionType.imageIdentification:
        return 'Identificación de imagen';
    }
  }

  String _difficultyLabel(QuizDifficulty difficulty) {
    switch (difficulty) {
      case QuizDifficulty.easy:
        return 'Fácil';
      case QuizDifficulty.medium:
        return 'Media';
      case QuizDifficulty.hard:
        return 'Difícil';
    }
  }
}

class _MultipleChoiceEditor extends StatefulWidget {
  final MultipleChoiceQuestion question;
  final ValueChanged<Question> onChanged;

  const _MultipleChoiceEditor({
    required this.question,
    required this.onChanged,
  });

  @override
  State<_MultipleChoiceEditor> createState() => _MultipleChoiceEditorState();
}

class _MultipleChoiceEditorState extends State<_MultipleChoiceEditor> {
  late List<ChoiceOption> options;

  @override
  void initState() {
    super.initState();
    options = List<ChoiceOption>.from(widget.question.options);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alternativas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...List.generate(options.length, (index) {
          final option = options[index];
          final selected = widget.question.correctOptionId == option.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('Correcta'),
                  selected: selected,
                  onSelected: (_) {
                    widget.onChanged(
                      MultipleChoiceQuestion(
                        id: widget.question.id,
                        statement: widget.question.statement,
                        options: widget.question.options,
                        correctOptionId: option.id,
                        imageUrl: widget.question.imageUrl,
                        explanation: widget.question.explanation,
                        difficulty: widget.question.difficulty,
                        score: widget.question.score,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: option.text),
                    decoration: InputDecoration(
                      labelText: 'Opción ${index + 1}',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final updatedOptions = List<ChoiceOption>.from(options);
                      updatedOptions[index] = ChoiceOption(
                        id: option.id,
                        text: value,
                      );
                      options = updatedOptions;
                      widget.onChanged(
                        MultipleChoiceQuestion(
                          id: widget.question.id,
                          statement: widget.question.statement,
                          options: updatedOptions,
                          correctOptionId: widget.question.correctOptionId,
                          imageUrl: widget.question.imageUrl,
                          explanation: widget.question.explanation,
                          difficulty: widget.question.difficulty,
                          score: widget.question.score,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _TrueFalseEditor extends StatelessWidget {
  final TrueFalseQuestion question;
  final ValueChanged<Question> onChanged;

  const _TrueFalseEditor({required this.question, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Respuesta correcta',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Verdadero')),
            ButtonSegment(value: false, label: Text('Falso')),
          ],
          selected: {question.correctAnswer},
          onSelectionChanged: (value) {
            if (value.isEmpty) return;
            onChanged(
              TrueFalseQuestion(
                id: question.id,
                statement: question.statement,
                correctAnswer: value.first,
                imageUrl: question.imageUrl,
                explanation: question.explanation,
                difficulty: question.difficulty,
                score: question.score,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _MatchingEditor extends StatelessWidget {
  final MatchingQuestion question;
  final ValueChanged<Question> onChanged;

  const _MatchingEditor({required this.question, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emparejamiento',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...question.pairs.asMap().entries.map((entry) {
          final index = entry.key;
          final pair = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: pair.left,
                    decoration: const InputDecoration(
                      labelText: 'Columna A',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final updatedPairs = List<MatchingPair>.from(
                        question.pairs,
                      );
                      updatedPairs[index] = MatchingPair(
                        left: value,
                        right: pair.right,
                      );
                      onChanged(
                        MatchingQuestion(
                          id: question.id,
                          statement: question.statement,
                          pairs: updatedPairs,
                          leftColumn: question.leftColumn,
                          rightColumn: question.rightColumn,
                          imageUrl: question.imageUrl,
                          explanation: question.explanation,
                          difficulty: question.difficulty,
                          score: question.score,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: pair.right,
                    decoration: const InputDecoration(
                      labelText: 'Columna B',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      final updatedPairs = List<MatchingPair>.from(
                        question.pairs,
                      );
                      updatedPairs[index] = MatchingPair(
                        left: pair.left,
                        right: value,
                      );
                      onChanged(
                        MatchingQuestion(
                          id: question.id,
                          statement: question.statement,
                          pairs: updatedPairs,
                          leftColumn: question.leftColumn,
                          rightColumn: question.rightColumn,
                          imageUrl: question.imageUrl,
                          explanation: question.explanation,
                          difficulty: question.difficulty,
                          score: question.score,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _FillBlankEditor extends StatelessWidget {
  final FillBlankQuestion question;
  final ValueChanged<Question> onChanged;

  const _FillBlankEditor({required this.question, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Huecos a completar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...question.blanks.asMap().entries.map((entry) {
          final index = entry.key;
          final blank = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextFormField(
              initialValue: blank.expectedAnswer,
              decoration: InputDecoration(
                labelText: 'Respuesta esperada ${index + 1}',
                border: const OutlineInputBorder(),
                suffixText: blank.hint ?? '',
              ),
              onChanged: (value) {
                final updatedBlanks = List<FillBlankAnswer>.from(
                  question.blanks,
                );
                updatedBlanks[index] = FillBlankAnswer(
                  id: blank.id,
                  expectedAnswer: value,
                  hint: blank.hint,
                );
                onChanged(
                  FillBlankQuestion(
                    id: question.id,
                    statement: question.statement,
                    blanks: updatedBlanks,
                    imageUrl: question.imageUrl,
                    explanation: question.explanation,
                    difficulty: question.difficulty,
                    score: question.score,
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}

class _PracticalProblemEditor extends StatelessWidget {
  final PracticalProblemQuestion question;
  final ValueChanged<Question> onChanged;

  const _PracticalProblemEditor({
    required this.question,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          initialValue: question.problemText,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: 'Enunciado del problema',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            onChanged(
              PracticalProblemQuestion(
                id: question.id,
                statement: question.statement,
                problemText: value,
                expectedSolution: question.expectedSolution,
                steps: question.steps,
                imageUrl: question.imageUrl,
                explanation: question.explanation,
                difficulty: question.difficulty,
                score: question.score,
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: question.expectedSolution,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Solución esperada',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            onChanged(
              PracticalProblemQuestion(
                id: question.id,
                statement: question.statement,
                problemText: question.problemText,
                expectedSolution: value,
                steps: question.steps,
                imageUrl: question.imageUrl,
                explanation: question.explanation,
                difficulty: question.difficulty,
                score: question.score,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _OrderingEditor extends StatelessWidget {
  final OrderingQuestion question;
  final ValueChanged<Question> onChanged;

  const _OrderingEditor({required this.question, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Elementos para ordenar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...question.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextFormField(
              initialValue: item,
              decoration: InputDecoration(
                labelText: 'Elemento ${index + 1}',
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                final updatedItems = List<String>.from(question.items);
                updatedItems[index] = value;
                onChanged(
                  OrderingQuestion(
                    id: question.id,
                    statement: question.statement,
                    items: updatedItems,
                    correctOrder: question.correctOrder,
                    imageUrl: question.imageUrl,
                    explanation: question.explanation,
                    difficulty: question.difficulty,
                    score: question.score,
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}

class _ImageIdentificationEditor extends StatelessWidget {
  final ImageIdentificationQuestion question;
  final ValueChanged<Question> onChanged;

  const _ImageIdentificationEditor({
    required this.question,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Imagen de referencia',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: question.imageUrlQuestion.isEmpty
                ? const Center(child: Text('Añadir imagen'))
                : const Center(child: Icon(Icons.image_outlined, size: 48)),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Opciones', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...question.options.asMap().entries.map((entry) {
          final index = entry.key;
          final option = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextFormField(
              initialValue: option.text,
              decoration: InputDecoration(
                labelText: 'Opción ${index + 1}',
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                final updatedOptions = List<ChoiceOption>.from(
                  question.options,
                );
                updatedOptions[index] = ChoiceOption(
                  id: option.id,
                  text: value,
                );
                onChanged(
                  ImageIdentificationQuestion(
                    id: question.id,
                    statement: question.statement,
                    imageUrlQuestion: question.imageUrlQuestion,
                    options: updatedOptions,
                    correctOptionId: question.correctOptionId,
                    explanation: question.explanation,
                    difficulty: question.difficulty,
                    score: question.score,
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}
