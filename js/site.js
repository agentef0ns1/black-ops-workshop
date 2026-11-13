(function () {
  function pack() {
    return (window.SITE_I18N && window.SITE_I18N.pack) || {};
  }

  function fillContact() {
    var course = window.COURSE || {};
    var email = (course.contactEmail || "").trim();
    var linkedin = (course.contactLinkedIn || "").trim();
    document.querySelectorAll("[data-contact-email]").forEach(function (node) {
      if (!email) {
        node.textContent = pack()["contact.missing"] || "";
        return;
      }
      node.textContent = email;
      if (node.tagName === "A") node.href = "mailto:" + email;
    });
    document.querySelectorAll("[data-contact-linkedin]").forEach(function (node) {
      if (!linkedin) {
        node.hidden = true;
        return;
      }
      node.hidden = false;
      if (node.tagName === "A") node.href = linkedin;
    });
  }

  function mountVideos() {
    document.querySelectorAll("[data-video]").forEach(function (node) {
      var spec = (window.COURSE && window.COURSE.videos || {})[node.getAttribute("data-video")];
      var empty = node.querySelector("[data-video-empty]");
      var frame = node.querySelector("iframe");
      if (!spec || !spec.id) {
        if (empty) empty.hidden = false;
        if (frame) frame.remove();
        return;
      }
      if (empty) empty.hidden = true;
      if (!frame) {
        frame = document.createElement("iframe");
        frame.allow = "accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share";
        frame.allowFullscreen = true;
        frame.referrerPolicy = "strict-origin-when-cross-origin";
        var start = Number(spec.start) || 0;
        var src = "https://www.youtube-nocookie.com/embed/" + spec.id + "?rel=0";
        if (start) src += "&start=" + start;
        frame.src = src;
        node.appendChild(frame);
      }
      var key = node.getAttribute("data-i18n-title");
      frame.title = (key && pack()[key]) || "YouTube";
    });
  }

  function mountScript() {
    document.querySelectorAll("[data-script]").forEach(function (node) {
      if (node.textContent.trim() || node.getAttribute("data-loaded")) return;
      node.setAttribute("data-loaded", "1");
      var url = node.getAttribute("data-script");
      fetch(url).then(function (response) {
        if (!response.ok) throw new Error("script");
        return response.text();
      }).then(function (text) {
        node.textContent = text;
      }).catch(function () {
        node.textContent = pack()["code.loadfail"] || "Open the script file from the link above.";
      });
    });
  }

  fillContact();
  mountVideos();
  mountScript();
  window.addEventListener("site-lang", function () {
    fillContact();
    mountVideos();
  });
})();
