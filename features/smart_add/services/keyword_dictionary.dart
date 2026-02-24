import 'package:flutter/material.dart';
import 'package:task_manager_app/features/tasks/models/task_model.dart';

class KeywordDictionary {
  // --- SYNONYMS MAPS ---

  static const Set<String> focusSynonyms = {
    'focus',
    'concentrate',
    'deep work',
    'session',
    'zone',
    'study',
    'work',
    'pomo',
    'pomodoro',
  };

  static const Set<String> habitSynonyms = {
    'habit',
    'routine',
    'ritual',
    'every',
    'everyday',
    'daily',
    'weekly',
    'monthly',
    'yearly',
    // Days
    'mon', 'monday', 'tue', 'tuesday', 'wed', 'wednesday',
    'thu', 'thursday', 'fri', 'friday', 'sat', 'saturday', 'sun', 'sunday',
    // Relative
    'tomorrow', 'today'
  };

  // --- NEW: SPLIT CONNECTORS (Added for Smart Split Logic) ---
  static const Set<String> splitConnectors = {
    'and',
    'also',
    'plus',
    'then',
    '&',
    '+',
    'meanwhile',
  };

  static const Map<String, TaskImportance> importanceMap = {
    // High
    'important': TaskImportance.high,
    'very important': TaskImportance.high,
    'urgent': TaskImportance.high,
    'must': TaskImportance.high,
    'critical': TaskImportance.high,
    '!high': TaskImportance.high,
    '!!!': TaskImportance.high,
    // Medium
    'medium': TaskImportance.medium,
    'should do': TaskImportance.medium,
    '!medium': TaskImportance.medium,
    '!!': TaskImportance.medium,
    // Low
    'low': TaskImportance.low,
    'optional': TaskImportance.low,
    'later': TaskImportance.low,
    '!low': TaskImportance.low,
    '!': TaskImportance.low,
  };

  // --- NATURAL TIME MAPS ---

  static const Map<String, TimeOfDay> timeKeywords = {
    'morning': TimeOfDay(hour: 9, minute: 0),
    'noon': TimeOfDay(hour: 12, minute: 0),
    'afternoon': TimeOfDay(hour: 14, minute: 0),
    'evening': TimeOfDay(hour: 18, minute: 0),
    'night': TimeOfDay(hour: 21, minute: 0),
    'midnight': TimeOfDay(hour: 0, minute: 0),
    'bedtime': TimeOfDay(hour: 22, minute: 0),
  };

  // --- NEW: PREPOSITION HELPER (Added for Parser Logic) ---
  // Helps distinguish "at" (trigger) from "Home" (value)
  static const Set<String> locationPrepositions = {
    'at',
    'in',
    'near',
    'next to',
    'close to',
    'by',
    'on',
  };

  // --- LOCATION DICTIONARY (MALAYSIA FOCUSED) ---
  static const Set<String> locationKeywords = {
    // Prepositions
    'at', 'in', 'near', 'next to', 'close to', 'by',

    // General Places
    'home', 'office', 'gym', 'cafe', 'library', 'store', 'shop', 'mall',
    'airport', 'station', 'room', 'floor', 'bldg', 'building',
    'st', 'street', 'rd', 'road', 'ave', 'avenue',

    // --- MALAYSIA SPECIFIC ---
    // States & Major Cities
    'melaka', 'malacca', 'kuala lumpur', 'kl', 'selangor', 'johor', 'penang',
    'cyberjaya', 'putrajaya', 'seremban', 'ipoh', 'jb', 'johor bahru',

    // Melaka Specifics
    'ayer keroh', 'bukit beruang', 'jonker', 'jonker walk', 'klebang',
    'bandar hilir', 'malim', 'cheng', 'batu berendam', 'jasin', 'alor gajah',
    'kota laksamana', 'taman merdeka', 'mitc', 'a famosa', 'stadthuys',
    'mahkota parade', 'dataran pahlawan', 'aeon', 'aeon bandaraya', 'the shore',

    // KL Specifics
    'klcc', 'bukit bintang', 'bangsar', 'damansara', 'ttdi', 'cheras',
    'petaling jaya', 'pj', 'subang', 'subang jaya', 'sunway', 'puchong',
    'shah alam', 'kepong', 'sentul', 'setapak', 'wangsa maju', 'brickfields',
    'mid valley', 'the gardens', 'pavilion', 'trx', 'kl sentral', 'nu sentral',
    'publika', '1 utama', 'the curve', 'ikea',

    // Universities (MMU & Others)
    'mmu', 'multimedia university', 'mmu melaka', 'mmu cyberjaya',
    'fist', 'fist building', 'fist lab', 'foe', 'fom', 'fci',
    'fcm', // MMU Faculties
    'clc', 'central lecture complex', 'grand hall', 'exam hall', // MMU Spots
    'uitm', 'um', 'universiti malaya', 'ukm', 'upm', 'utm', 'usm',
    'taylors', 'sunway university', 'monash', 'inti', 'ucsi', 'tar uc',
    'unikl', 'imu', 'apu', 'help university', 'manipal', 'utem',
  };

  // --- FOLDER CATEGORIES ---
  static const Map<String, List<String>> folderKeywords = {
    'Health': [
      'gym',
      'yoga',
      'run',
      'running',
      'meditate',
      'water',
      'vitamin',
      'workout',
      'swimming',
      'diet',
      'protein',
      'sleep',
      'doctor',
      'dentist',
      'pill',
      'cardio'
    ],
    'Study': [
      'exam',
      'quiz',
      'assignment',
      'read',
      'reading',
      'physics',
      'math',
      'research',
      'paper',
      'essay',
      'homework',
      'tutorial',
      'notes',
      'revise',
      'memorize',
      'textbook'
    ],
    'Uni': [
      'lecture',
      'seminar',
      'lab',
      'professor',
      'campus',
      'class',
      'society',
      'club',
      'dorm',
      'fee',
      'transcript',
      'thesis',
      'final year project',
      'fyp'
    ],
    'Work': [
      'meeting',
      'email',
      'report',
      'client',
      'presentation',
      'call',
      'standup',
      'boss',
      'manager',
      'deadline',
      'project',
      'pitch',
      'coding',
      'debug',
      'deploy'
    ],
    'Chores': [
      'laundry',
      'clean',
      'groceries',
      'cook',
      'trash',
      'dishes',
      'tidy',
      'sweep',
      'mop',
      'vacuum',
      'dust',
      'iron',
      'fix',
      'repair',
      'bills',
      'rent'
    ],
    'Personal': [
      'movie',
      'game',
      'friend',
      'birthday',
      'party',
      'dinner',
      'date',
      'cinema',
      'netflix',
      'relax',
      'spa',
      'haircut',
      'shopping',
      'gift',
      'family',
      'mom',
      'dad'
    ],
    'Daily': [
      'read',
      'journal',
      'meditate',
      'stretch',
      'wake up',
      'shower',
      'breakfast',
      'lunch',
      'dinner',
      'brush teeth',
      'commute',
      'drive'
    ],
  };

  // --- TYPO CORRECTION ---
  static const Map<String, String> typoMap = {
    // Focus
    'focuse': 'focus', 'focs': 'focus', 'foucs': 'focus',
    'concentrat': 'concentrate',
    'sesion': 'session', 'pomodor': 'pomodoro', 'pmodoro': 'pomodoro',

    // Habit
    'hbit': 'habit', 'abit': 'habit', 'routin': 'routine', 'evry': 'every',
    'dy': 'day',
    'weekky': 'weekly', 'mnthly': 'monthly', 'yerly': 'yearly',

    // Priority
    'impotant': 'important', 'importent': 'important', 'imprtant': 'important',
    'urgentt': 'urgent', 'critcal': 'critical', 'mst': 'must',
    'crtical': 'critical',

    // Location
    'locotion': 'location', 'lcation': 'location', 'plac': 'place',
    'whre': 'where', 'hom': 'home', 'offce': 'office', 'gim': 'gym',

    // Time
    'tmie': 'time', 'tme': 'time', 'oclock': 'o\'clock', 'clck': 'clock',
    'mnt': 'minute', 'minit': 'minute', 'hr': 'hour', 'hor': 'hour',
  };
}
