// Tilt 3D + burst SVG en la landing /comunidad/

(function () {
  function initTilt(id) {
    const el = document.getElementById(id);
    if (!el) return;
    el.style.willChange = "transform";
    el.addEventListener("mousemove", (e) => {
      const r = el.getBoundingClientRect();
      const x = (e.clientX - r.left) / r.width - 0.5;
      const y = (e.clientY - r.top)  / r.height - 0.5;
      const MAX = 4;
      el.style.transition = "transform .08s linear";
      el.style.transform =
        "perspective(900px) rotateX(" + (-y * MAX) + "deg) rotateY(" + (x * MAX) + "deg) translateZ(0)";
    });
    el.addEventListener("mouseleave", () => {
      el.style.transition = "transform .6s cubic-bezier(.22,1,.36,1)";
      el.style.transform = "perspective(900px) rotateX(0deg) rotateY(0deg) translateZ(0)";
    });
  }
  setTimeout(() => { initTilt("card-pool"); initTilt("card-referidos"); }, 200);
})();

// Burst SVG en la card Pool al hacer click sobre la zona visual
(function () {
  const wrap = document.getElementById("visual-pool");
  if (!wrap) return;
  let firing = false;
  wrap.addEventListener("click", (e) => {
    // Si pulsa botón dentro, no animar
    if (e.target.closest("button, a")) return;
    if (firing) return;
    firing = true;
    const nodes = document.querySelectorAll("#poolNodes .sat circle:first-child");
    const extraNodes = document.getElementById("extraNodes");
    const lines = document.getElementById("poolLines");
    const glow = document.getElementById("poolGlow");
    const r1 = document.getElementById("burstRing1");
    const r2 = document.getElementById("burstRing2");
    [r1, r2].forEach((r, i) => {
      r.style.transition = "none";
      r.setAttribute("r", "10");
      r.setAttribute("stroke-opacity", i === 0 ? ".8" : ".5");
      setTimeout(() => {
        r.style.transition = "r .6s ease-out, stroke-opacity .6s ease-out";
        r.setAttribute("r", "200");
        r.setAttribute("stroke-opacity", "0");
      }, i * 80);
    });
    setTimeout(() => { glow.style.transition = "all .3s"; glow.setAttribute("rx", "360"); glow.setAttribute("ry", "300"); glow.setAttribute("fill-opacity", ".35"); }, 50);
    setTimeout(() => { glow.style.transition = "all .8s"; glow.setAttribute("rx", "220"); glow.setAttribute("ry", "170"); glow.setAttribute("fill-opacity", "1"); }, 350);
    nodes.forEach((n, i) => {
      const ox = parseFloat(n.getAttribute("cx"));
      const oy = parseFloat(n.getAttribute("cy"));
      const dx = (ox - 300) * 1.6;
      const dy = (oy - 260) * 1.6;
      setTimeout(() => {
        n.style.transition = "transform .3s ease-out, opacity .3s";
        n.style.transform = "translate(" + dx + "px," + dy + "px)";
        n.style.opacity = "0";
      }, i * 40);
    });
    setTimeout(() => { lines.style.transition = "opacity .2s"; lines.style.opacity = "0"; }, 100);
    setTimeout(() => { extraNodes.style.transition = "opacity .4s"; extraNodes.style.opacity = "1"; }, 300);
    nodes.forEach((n, i) => {
      setTimeout(() => {
        n.style.transition = "transform .5s cubic-bezier(.34,1.56,.64,1), opacity .4s";
        n.style.transform = "translate(0,0)";
        n.style.opacity = "1";
      }, 500 + i * 60);
    });
    setTimeout(() => { lines.style.transition = "opacity .4s"; lines.style.opacity = "1"; extraNodes.style.opacity = "0"; }, 800);
    setTimeout(() => { firing = false; }, 1200);
  });
})();
