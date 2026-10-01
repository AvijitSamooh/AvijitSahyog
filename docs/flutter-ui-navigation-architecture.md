# Flutter UI & Navigation Architecture

## Purpose

This document is the implementation contract for adding or changing Flutter pages in Avijit Sahyog. It prevents feature pages from accidentally creating competing application shells, duplicated navigation, or inconsistent failure-state UX.

## Application shell

HomePage owns the primary application shell:

- one root Scaffold;
- shared application AppBar;
- primary AppNavigationBar;
- primary-tab IndexedStack;
- AppShellScope navigation state.

Primary bottom-navigation destinations are body content, not independent application shells.

### Primary tab rule

A page rendered directly by the HomePage IndexedStack must not create:

- a Scaffold containing an application AppBar;
- an AppBar;
- an AppNavigationBar;
- another primary navigation controller.

If a tab needs a title or controls, those controls belong to the shell or must use an explicit shell configuration mechanism.

## Page classification

Before implementing a page, classify it:

### A. Primary tab body

Examples: Home, Applications, Impact, Information, Profile.

Implementation:

- body widget only;
- no primary AppBar;
- no bottom navigation;
- no independent shell.

### B. Secondary/detail/admin route

Examples: cause detail, beneficiary detail, admin dashboard, or authenticated routes opened from a secondary action.

Implementation:

- use AppPageScaffold;
- do not add AppNavigationBar manually;
- shared scaffold provides common AppBar/settings actions and shared navigation when the route is inside the application shell.

### C. Standalone flow

Use an independent Scaffold only when the flow genuinely needs an independent navigation context, such as a multi-step setup or isolated system interaction. Document why it is independent and add navigation regression coverage.

## Navigation rules

- Selecting an existing primary destination changes the shell navigation controller; it does not Navigator.push another copy of the tab.
- Navigating to a secondary page may use Navigator.push.
- Returning from a secondary page restores the correct primary destination.
- Never put a second bottom navigation bar inside a primary tab.
- Shared navigation widgets must safely handle widget tests or isolated routes that do not have AppShellScope.

## Localization and settings UX

Supported languages are English, Hindi, Marathi and Gujarati.

Language selection is a setting, not a primary navigation destination. The Information surface may expose language selection, and the top-right application menu also provides access.

Language selection must remain compact. Prefer a compact grid/list or modal selection rather than large full-width cards.

Every language option must:

- use the localized language label;
- show the current selection;
- provide a clear tap target;
- update the shared locale;
- avoid consuming unnecessary vertical space.

## Required tests for every new page

Add tests appropriate to the classification:

- primary tab: exactly one shell AppBar and one primary navigation bar;
- secondary route: shared AppPageScaffold/navigation is present;
- standalone flow: independent shell and exit/back behaviour are tested;
- loading state where applicable;
- empty state where applicable;
- backend/service failure;
- retry/recovery where applicable;
- localized strings for every supported locale when new copy is introduced.

## Definition of done

A page is not complete when it merely renders successfully. Its shell classification, navigation behaviour, error states, localization, tests and documentation must agree.
