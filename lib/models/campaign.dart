enum CampaignStatus { draft, active, paused, completed }

enum InteractionType { quiz, survey, poll, feedback }

extension CampaignStatusLabel on CampaignStatus {
  String get label {
    switch (this) {
      case CampaignStatus.draft:
        return 'Draft';
      case CampaignStatus.active:
        return 'Active';
      case CampaignStatus.paused:
        return 'Paused';
      case CampaignStatus.completed:
        return 'Completed';
    }
  }
}

extension InteractionTypeLabel on InteractionType {
  String get label {
    switch (this) {
      case InteractionType.quiz:
        return 'Quiz';
      case InteractionType.survey:
        return 'Survey';
      case InteractionType.poll:
        return 'Poll';
      case InteractionType.feedback:
        return 'Feedback';
    }
  }
}

class CampaignInteraction {
  const CampaignInteraction({
    required this.type,
    required this.question,
    required this.options,
    this.correctAnswer,
  });

  final InteractionType type;
  final String question;
  final List<String> options;
  final String? correctAnswer;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'question': question,
        'options': options,
        'correctAnswer': correctAnswer,
      };

  factory CampaignInteraction.fromJson(Map<String, dynamic> json) =>
      CampaignInteraction(
        type: InteractionType.values.byName(json['type'] as String),
        question: json['question'] as String,
        options: List<String>.from(json['options'] as List<dynamic>),
        correctAnswer: json['correctAnswer'] as String?,
      );
}

class Campaign {
  const Campaign({
    required this.id,
    required this.name,
    required this.description,
    required this.youtubeUrl,
    required this.youtubeVideoId,
    required this.budget,
    required this.rewardPerCompletion,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.interactions,
    required this.views,
    required this.completions,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String description;
  final String youtubeUrl;
  final String youtubeVideoId;
  final double budget;
  final double rewardPerCompletion;
  final DateTime startDate;
  final DateTime endDate;
  final CampaignStatus status;
  final List<CampaignInteraction> interactions;
  final int views;
  final int completions;
  final DateTime createdAt;

  double get spent => completions * rewardPerCompletion;

  double get remainingBudget => budget - spent < 0 ? 0 : budget - spent;

  double get completionRate => views == 0 ? 0 : completions / views;

  Campaign copyWith({
    String? id,
    String? name,
    String? description,
    String? youtubeUrl,
    String? youtubeVideoId,
    double? budget,
    double? rewardPerCompletion,
    DateTime? startDate,
    DateTime? endDate,
    CampaignStatus? status,
    List<CampaignInteraction>? interactions,
    int? views,
    int? completions,
    DateTime? createdAt,
  }) {
    return Campaign(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      youtubeVideoId: youtubeVideoId ?? this.youtubeVideoId,
      budget: budget ?? this.budget,
      rewardPerCompletion: rewardPerCompletion ?? this.rewardPerCompletion,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      interactions: interactions ?? this.interactions,
      views: views ?? this.views,
      completions: completions ?? this.completions,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'youtubeUrl': youtubeUrl,
        'youtubeVideoId': youtubeVideoId,
        'budget': budget,
        'rewardPerCompletion': rewardPerCompletion,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'status': status.name,
        'interactions': interactions.map((item) => item.toJson()).toList(),
        'views': views,
        'completions': completions,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Campaign.fromJson(Map<String, dynamic> json) => Campaign(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        youtubeUrl: (json['youtubeUrl'] ?? json['videoUrl']) as String,
        youtubeVideoId: (json['youtubeVideoId'] ??
            extractYouTubeVideoId((json['youtubeUrl'] ?? json['videoUrl']) as String) ??
            '') as String,
        budget: (json['budget'] as num).toDouble(),
        rewardPerCompletion: (json['rewardPerCompletion'] as num).toDouble(),
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: DateTime.parse(json['endDate'] as String),
        status: CampaignStatus.values.byName(json['status'] as String),
        interactions: (json['interactions'] as List<dynamic>)
            .map((item) =>
                CampaignInteraction.fromJson(item as Map<String, dynamic>))
            .toList(),
        views: json['views'] as int,
        completions: json['completions'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

String? extractYouTubeVideoId(String url) {
  final value = url.trim();
  if (value.isEmpty) return null;

  final uri = Uri.tryParse(value);
  if (uri == null) return null;

  final host = uri.host.toLowerCase().replaceFirst('www.', '');
  if (host == 'youtu.be') {
    final id = uri.pathSegments.isEmpty ? null : uri.pathSegments.first;
    return _cleanYouTubeId(id);
  }

  if (host == 'youtube.com' || host == 'm.youtube.com' || host == 'music.youtube.com') {
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'embed') {
      return _cleanYouTubeId(uri.pathSegments.length > 1 ? uri.pathSegments[1] : null);
    }
    if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'shorts') {
      return _cleanYouTubeId(uri.pathSegments.length > 1 ? uri.pathSegments[1] : null);
    }
    return _cleanYouTubeId(uri.queryParameters['v']);
  }

  return null;
}

String? _cleanYouTubeId(String? id) {
  if (id == null || id.isEmpty) return null;
  final clean = id.split('?').first.split('&').first;
  final valid = RegExp(r'^[A-Za-z0-9_-]{6,}$').hasMatch(clean);
  return valid ? clean : null;
}
