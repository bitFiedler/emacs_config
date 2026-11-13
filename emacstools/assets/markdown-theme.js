(function () {
  'use strict';
  // Native radio controls and CSS switch colors even if scripts are blocked.
  // JavaScript remembers the choice and hides the control while scrolled.
  var key = 'emacs-markdown-theme';
  function install() {
    var controls = document.querySelectorAll('#emacs-markdown-theme-chooser');
    if (!controls.length) return;
    var chooser = controls[0];
    for (var i = 1; i < controls.length; i++) controls[i].remove();
    if (chooser.parentNode !== document.body) document.body.appendChild(chooser);
    var selected = window.emacsMarkdownThemeSelection || 'dark';
    try {
      var saved = window.localStorage.getItem(key);
      if (saved === 'dark' || saved === 'light') selected = saved;
    } catch (_) {}
    function apply(theme) {
      window.emacsMarkdownThemeSelection = theme;
      document.documentElement.setAttribute('data-emacs-markdown-theme', theme);
      chooser.querySelectorAll('input').forEach(function (input) {
        input.checked = input.value === theme;
      });
    }
    apply(selected);
    if (!window.emacsMarkdownThemeUpdateVisibility) {
      window.emacsMarkdownThemeUpdateVisibility = function () {
        var control = document.getElementById('emacs-markdown-theme-chooser');
        if (control) {
          control.hidden = (window.scrollY || document.documentElement.scrollTop || 0) > 0;
        }
      };
      window.addEventListener('scroll', window.emacsMarkdownThemeUpdateVisibility, {passive: true});
    }
    window.emacsMarkdownThemeUpdateVisibility();
    if (!chooser.emacsThemeInstalled) {
      chooser.addEventListener('change', function (event) {
        if (event.target.type !== 'radio') return;
        apply(event.target.value);
        try { window.localStorage.setItem(key, event.target.value); } catch (_) {}
      });
      chooser.emacsThemeInstalled = true;
    }
  }
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', install, {once: true});
  } else {
    install();
  }
}());
