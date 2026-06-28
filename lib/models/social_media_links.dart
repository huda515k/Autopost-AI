class SocialMediaLinks {
  final String username;
  final String? instagram;
  final String? twitter;
  final String? linkedin;
  final String? facebook;
  final bool instagramPublic;
  final bool twitterPublic;
  final bool linkedinPublic;
  final bool facebookPublic;
  final DateTime updatedAt;

  SocialMediaLinks({
    required this.username,
    this.instagram,
    this.twitter,
    this.linkedin,
    this.facebook,
    this.instagramPublic = true,
    this.twitterPublic = true,
    this.linkedinPublic = true,
    this.facebookPublic = true,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'instagram': instagram,
      'twitter': twitter,
      'linkedin': linkedin,
      'facebook': facebook,
      'instagram_public': instagramPublic ? 1 : 0,
      'twitter_public': twitterPublic ? 1 : 0,
      'linkedin_public': linkedinPublic ? 1 : 0,
      'facebook_public': facebookPublic ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory SocialMediaLinks.fromJson(Map<String, dynamic> json) {
    return SocialMediaLinks(
      username: json['username'] as String,
      instagram: json['instagram'] as String?,
      twitter: json['twitter'] as String?,
      linkedin: json['linkedin'] as String?,
      facebook: json['facebook'] as String?,
      instagramPublic: (json['instagram_public'] as int? ?? 1) == 1,
      twitterPublic: (json['twitter_public'] as int? ?? 1) == 1,
      linkedinPublic: (json['linkedin_public'] as int? ?? 1) == 1,
      facebookPublic: (json['facebook_public'] as int? ?? 1) == 1,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  SocialMediaLinks copyWith({
    String? username,
    String? instagram,
    String? twitter,
    String? linkedin,
    String? facebook,
    bool? instagramPublic,
    bool? twitterPublic,
    bool? linkedinPublic,
    bool? facebookPublic,
    DateTime? updatedAt,
  }) {
    return SocialMediaLinks(
      username: username ?? this.username,
      instagram: instagram ?? this.instagram,
      twitter: twitter ?? this.twitter,
      linkedin: linkedin ?? this.linkedin,
      facebook: facebook ?? this.facebook,
      instagramPublic: instagramPublic ?? this.instagramPublic,
      twitterPublic: twitterPublic ?? this.twitterPublic,
      linkedinPublic: linkedinPublic ?? this.linkedinPublic,
      facebookPublic: facebookPublic ?? this.facebookPublic,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
