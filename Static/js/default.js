var links = $(selector);
links.each(function(i, e) {
  var a = document.createElement("a");
  a.setAttribute("href", e.href);
  a.innerText = e.innerText;
  ahkReaderContainer.appendChild(a);
});
