# Rayen Mobile UI Scorecard and Refactor Checklist

## Scoring Method

- Scale: `1` (weak) to `5` (strong)
- Metrics:
  - `Hierarchy`: primary vs secondary visual priority clarity
  - `Readability`: typography and contrast legibility
  - `Density`: information load and scan speed
  - `CTA`: clarity of primary action
  - `Consistency`: alignment with app-wide visual patterns

## Per-Screen Scorecard

| Screen | Hierarchy | Readability | Density | CTA | Consistency | Notes |
|---|---:|---:|---:|---:|---:|---|
| `authentication/login_screen.dart` | 4 | 4 | 3 | 5 | 5 | Strong CTA, slightly decorative heavy |
| `authentication/register_screen.dart` | 4 | 4 | 3 | 5 | 5 | Good form flow, long page density |
| `authentication/splash_screen.dart` | 4 | 4 | 4 | 3 | 5 | Brand-forward, mostly transitional |
| `admin/admin_dashboard_screen.dart` | 3 | 4 | 2 | 3 | 4 | Rich data, hierarchy can flatten |
| `admin/admin_users_screen.dart` | 4 | 4 | 3 | 4 | 4 | Good tabs, list actions crowded |
| `admin/admin_courses_screen.dart` | 4 | 4 | 3 | 4 | 4 | Analytics clear, card content dense |
| `admin/admin_sessions_screen.dart` | 4 | 4 | 3 | 4 | 4 | Solid status visuals, many blocks |
| `admin/admin_categories_screen.dart` | 4 | 5 | 4 | 3 | 4 | Clean and readable simple tree view |
| `course/course_screen.dart` | 3 | 4 | 2 | 4 | 4 | Listing cards overloaded with metadata |
| `course/course_detail_screen.dart` | 4 | 4 | 3 | 5 | 4 | Strong structure, too many highlight cards |
| `instructor/instructor_dashboard_screen.dart` | 3 | 4 | 3 | 4 | 4 | Drawer + bottom nav duplication |
| `organizer/organizer_dashboard_screen.dart` | 4 | 3 | 3 | 4 | 4 | Good layout; small compact text in stats |
| `organizer/organizer_courses_screen.dart` | 3 | 4 | 3 | 3 | 4 | Many equal-priority actions on cards |
| `organizer/organizer_course_form_screen.dart` | 4 | 4 | 3 | 5 | 4 | Long but structured wizard-like form |
| `organizer/organizer_lessons_screen.dart` | 4 | 4 | 4 | 4 | 4 | Efficient CRUD pattern |
| `profile/profile_screen.dart` | 4 | 4 | 4 | 4 | 5 | Strong role identity, balanced layout |
| `profile/complete_profile_screen.dart` | 4 | 4 | 3 | 5 | 5 | Good onboarding progression |
| `student/student_home_screen.dart` | 3 | 4 | 4 | 3 | 4 | Neutral shell; hierarchy delegated to tabs |
| `subscription/subscription_screen.dart` | 4 | 4 | 3 | 5 | 4 | Premium funnel, high saturation load |
| `training/trainer_dashboard_screen.dart` | 4 | 4 | 3 | 4 | 4 | Good role-centric dashboard |
| `training/trainer_sessions_screen.dart` | 4 | 4 | 3 | 4 | 4 | Stable list layout, metadata compact |
| `training/student_sessions_screen.dart` | 4 | 4 | 3 | 4 | 4 | Good discovery flow, chip/badge busyness |
| `training/student_session_detail_screen.dart` | 4 | 4 | 3 | 5 | 4 | Strong CTA and sectioning |
| `training/student_enrollments_screen.dart` | 4 | 4 | 3 | 4 | 4 | Clear status semantics |
| `training/organizer_sessions_screen.dart` | 4 | 4 | 3 | 4 | 4 | Good management view, action density risk |
| `training/organizer_enrollments_screen.dart` | 4 | 4 | 3 | 5 | 4 | Strong triage actions |

## Refactor Checklist (Execution Order)

## Phase 1: High Impact, Low Risk

- [ ] Enforce one dominant emphasis per section (`hero`, `badge group`, or `gradient card`) on dashboard-like screens.
- [ ] Reduce metadata in course/session list cards to top 2-3 signals (title, price/status, one secondary metric).
- [ ] Normalize minimum text size for dense stat labels (`>= 11sp`).
- [ ] Ensure one primary CTA per card; move secondary/destructive actions into overflow menus.
- [ ] Run contrast pass for text/icons on gradients and tinted backgrounds.

## Phase 2: Hierarchy and Navigation Simplification

- [ ] Evaluate shell complexity on role dashboards (`drawer` + `bottom nav`) and keep one primary navigation pattern.
- [ ] Standardize section header pattern (icon chip + title + optional action) across admin/training/organizer screens.
- [ ] Normalize card radii and shadow strength tiers:
  - small card: `radius 12-16`, low shadow
  - feature card: `radius 20`, medium shadow
  - hero block: strong background, minimal competing decoration
- [ ] Align chip semantics consistently:
  - `success` = approved/published/free success state
  - `warning` = draft/pending
  - `error` = rejected/destructive
  - `info/primary` = neutral informational state

## Phase 3: Form and Dense Workflow Improvements

- [ ] Add section progress affordance for long forms (organizer course form, complete profile info step).
- [ ] Promote required field clarity (visual marker + inline helper text before submit).
- [ ] Increase tappable spacing in rows with multiple action icons.
- [ ] Defer low-priority details behind expandable panels in enrollment/session cards.

## Targeted File Groups

- **Dashboard heavy screens**
  - `lib/features/admin/presentation/screens/admin_dashboard_screen.dart`
  - `lib/features/instructor/presentation/screens/instructor_dashboard_screen.dart`
  - `lib/features/organizer/presentation/screens/organizer_dashboard_screen.dart`
  - `lib/features/training/presentation/screens/trainer_dashboard_screen.dart`

- **Dense listing/detail screens**
  - `lib/features/course/presentation/screens/course_screen.dart`
  - `lib/features/course/presentation/screens/course_detail_screen.dart`
  - `lib/features/training/presentation/screens/student_sessions_screen.dart`
  - `lib/features/training/presentation/screens/student_session_detail_screen.dart`

- **Management action-heavy screens**
  - `lib/features/admin/presentation/screens/admin_users_screen.dart`
  - `lib/features/organizer/presentation/screens/organizer_courses_screen.dart`
  - `lib/features/training/presentation/screens/organizer_sessions_screen.dart`
  - `lib/features/training/presentation/screens/organizer_enrollments_screen.dart`

## Done Criteria

- [ ] Every primary screen has one obvious top-priority action within first viewport.
- [ ] No repeated high-emphasis zones competing in same block.
- [ ] Compact text never below readable threshold.
- [ ] Status and semantic color meanings are uniform across roles/features.
- [ ] Scan time reduced for list cards (validated by quick team review on 5 random screens).

