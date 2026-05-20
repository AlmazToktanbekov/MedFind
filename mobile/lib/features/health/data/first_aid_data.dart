import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

class FirstAidCategory {
  final String id;
  final String emoji;
  final Color bgColor;
  final Color accentColor;
  final String Function(AppLocalizations l) titleOf;
  final String Function(AppLocalizations l) warningOf;
  final String Function(AppLocalizations l) stepsRawOf;

  const FirstAidCategory({
    required this.id,
    required this.emoji,
    required this.bgColor,
    required this.accentColor,
    required this.titleOf,
    required this.warningOf,
    required this.stepsRawOf,
  });

  String title(AppLocalizations l) => titleOf(l);
  String? warning(AppLocalizations l) {
    final w = warningOf(l);
    return w.isEmpty ? null : w;
  }

  List<String> steps(AppLocalizations l) =>
      stepsRawOf(l).split('\n').where((s) => s.isNotEmpty).toList();
}

const List<FirstAidCategory> firstAidCategories = [
  FirstAidCategory(
    id: 'heart-attack',
    emoji: '🫀',
    bgColor: Color(0xFFFFEBEE),
    accentColor: Color(0xFFC62828),
    titleOf: _heartAttackTitle,
    warningOf: _heartAttackWarning,
    stepsRawOf: _heartAttackSteps,
  ),
  FirstAidCategory(
    id: 'stroke',
    emoji: '🧠',
    bgColor: Color(0xFFE8EAF6),
    accentColor: Color(0xFF283593),
    titleOf: _strokeTitle,
    warningOf: _strokeWarning,
    stepsRawOf: _strokeSteps,
  ),
  FirstAidCategory(
    id: 'burns',
    emoji: '🔥',
    bgColor: Color(0xFFFFF3E0),
    accentColor: Color(0xFFE65100),
    titleOf: _burnsTitle,
    warningOf: _burnsWarning,
    stepsRawOf: _burnsSteps,
  ),
  FirstAidCategory(
    id: 'bleeding',
    emoji: '🩸',
    bgColor: Color(0xFFFCE4EC),
    accentColor: Color(0xFFAD1457),
    titleOf: _bleedingTitle,
    warningOf: _bleedingWarning,
    stepsRawOf: _bleedingSteps,
  ),
  FirstAidCategory(
    id: 'fractures',
    emoji: '🦴',
    bgColor: Color(0xFFE3F2FD),
    accentColor: Color(0xFF1565C0),
    titleOf: _fracturesTitle,
    warningOf: _fracturesWarning,
    stepsRawOf: _fracturesSteps,
  ),
  FirstAidCategory(
    id: 'poisoning',
    emoji: '💊',
    bgColor: Color(0xFFE8F5E9),
    accentColor: Color(0xFF2E7D32),
    titleOf: _poisoningTitle,
    warningOf: _poisoningWarning,
    stepsRawOf: _poisoningSteps,
  ),
  FirstAidCategory(
    id: 'heat-stroke',
    emoji: '🌡️',
    bgColor: Color(0xFFFFFDE7),
    accentColor: Color(0xFFF57F17),
    titleOf: _heatStrokeTitle,
    warningOf: _heatStrokeWarning,
    stepsRawOf: _heatStrokeSteps,
  ),
  FirstAidCategory(
    id: 'fainting',
    emoji: '😵',
    bgColor: Color(0xFFF3E5F5),
    accentColor: Color(0xFF6A1B9A),
    titleOf: _faintingTitle,
    warningOf: _faintingWarning,
    stepsRawOf: _faintingSteps,
  ),
  FirstAidCategory(
    id: 'drowning',
    emoji: '💧',
    bgColor: Color(0xFFE0F7FA),
    accentColor: Color(0xFF00838F),
    titleOf: _drowningTitle,
    warningOf: _drowningWarning,
    stepsRawOf: _drowningSteps,
  ),
  FirstAidCategory(
    id: 'electric-shock',
    emoji: '⚡',
    bgColor: Color(0xFFFFF8E1),
    accentColor: Color(0xFFFF6F00),
    titleOf: _electricShockTitle,
    warningOf: _electricShockWarning,
    stepsRawOf: _electricShockSteps,
  ),
  FirstAidCategory(
    id: 'anaphylaxis',
    emoji: '🤧',
    bgColor: Color(0xFFE0F2F1),
    accentColor: Color(0xFF00695C),
    titleOf: _anaphylaxisTitle,
    warningOf: _anaphylaxisWarning,
    stepsRawOf: _anaphylaxisSteps,
  ),
  FirstAidCategory(
    id: 'animal-bite',
    emoji: '🐾',
    bgColor: Color(0xFFF9FBE7),
    accentColor: Color(0xFF558B2F),
    titleOf: _animalBiteTitle,
    warningOf: _animalBiteWarning,
    stepsRawOf: _animalBiteSteps,
  ),
];

String _heartAttackTitle(AppLocalizations l) => l.firstAidHeartAttackTitle;
String _heartAttackWarning(AppLocalizations l) => l.firstAidHeartAttackWarning;
String _heartAttackSteps(AppLocalizations l) => l.firstAidHeartAttackSteps;

String _strokeTitle(AppLocalizations l) => l.firstAidStrokeTitle;
String _strokeWarning(AppLocalizations l) => l.firstAidStrokeWarning;
String _strokeSteps(AppLocalizations l) => l.firstAidStrokeSteps;

String _burnsTitle(AppLocalizations l) => l.firstAidBurnsTitle;
String _burnsWarning(AppLocalizations l) => l.firstAidBurnsWarning;
String _burnsSteps(AppLocalizations l) => l.firstAidBurnsSteps;

String _bleedingTitle(AppLocalizations l) => l.firstAidBleedingTitle;
String _bleedingWarning(AppLocalizations l) => l.firstAidBleedingWarning;
String _bleedingSteps(AppLocalizations l) => l.firstAidBleedingSteps;

String _fracturesTitle(AppLocalizations l) => l.firstAidFracturesTitle;
String _fracturesWarning(AppLocalizations l) => l.firstAidFracturesWarning;
String _fracturesSteps(AppLocalizations l) => l.firstAidFracturesSteps;

String _poisoningTitle(AppLocalizations l) => l.firstAidPoisoningTitle;
String _poisoningWarning(AppLocalizations l) => l.firstAidPoisoningWarning;
String _poisoningSteps(AppLocalizations l) => l.firstAidPoisoningSteps;

String _heatStrokeTitle(AppLocalizations l) => l.firstAidHeatStrokeTitle;
String _heatStrokeWarning(AppLocalizations l) => l.firstAidHeatStrokeWarning;
String _heatStrokeSteps(AppLocalizations l) => l.firstAidHeatStrokeSteps;

String _faintingTitle(AppLocalizations l) => l.firstAidFaintingTitle;
String _faintingWarning(AppLocalizations l) => l.firstAidFaintingWarning;
String _faintingSteps(AppLocalizations l) => l.firstAidFaintingSteps;

String _drowningTitle(AppLocalizations l) => l.firstAidDrowningTitle;
String _drowningWarning(AppLocalizations l) => l.firstAidDrowningWarning;
String _drowningSteps(AppLocalizations l) => l.firstAidDrowningSteps;

String _electricShockTitle(AppLocalizations l) => l.firstAidElectricShockTitle;
String _electricShockWarning(AppLocalizations l) =>
    l.firstAidElectricShockWarning;
String _electricShockSteps(AppLocalizations l) => l.firstAidElectricShockSteps;

String _anaphylaxisTitle(AppLocalizations l) => l.firstAidAnaphylaxisTitle;
String _anaphylaxisWarning(AppLocalizations l) => l.firstAidAnaphylaxisWarning;
String _anaphylaxisSteps(AppLocalizations l) => l.firstAidAnaphylaxisSteps;

String _animalBiteTitle(AppLocalizations l) => l.firstAidAnimalBiteTitle;
String _animalBiteWarning(AppLocalizations l) => l.firstAidAnimalBiteWarning;
String _animalBiteSteps(AppLocalizations l) => l.firstAidAnimalBiteSteps;
