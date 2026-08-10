// ============================================================
// nav.js
// HEAVY HAUL COMMAND — SHARED GLOBAL NAVIGATION
// ============================================================

(function () {
  'use strict';

  const MAIN_NAV = [
    ['welcome.html', 'Welcome', 'welcome'],
    ['board.html', 'Dispatch', 'dispatch'],
    ['sourcing.html', 'Sourcing', 'sourcing'],
    ['fleet-command.html', 'Fleet Command', 'fleet']
  ];

  const HUB_PAGES = {
    welcome: [
      'welcome.html'
    ],

    dispatch: [
      'dispatch.html',
      'board.html',
      'newload.html',
      'loads.html',
      'workspace.html'
    ],

    sourcing: [
      'sourcing.html',
      'opportunities.html',
      'call-queue.html',
      'portals.html',
      'load-emails.html',
      'inbox.html',
      'templates.html',
      'field-manual.html',
      'calculators.html'
    ],

    fleet: [
      'fleet-command.html',
      'fleet.html',
      'route-planning.html',
      'states.html',
      'calendar.html'
    ]
  };

  function currentPage() {
    return location.pathname.split('/').pop() || 'welcome.html';
  }
