elements = $("body > section > table:nth-child(3) > tbody > tr > td > div > div > ul > li > dt");
elements.each(function(){
  var a = document.createElement("a");
  var title = $(this).children("a").text();
  var href = "http://www.ccdi.gov.cn/fgk/" + $(this).children("form").attr("action");
  a.setAttribute("href", href);
  a.setAttribute("headers", "Referer:http://www.ccdi.gov.cn/fgk/index");
  a.innerText = title;
  ahkReaderContainer.appendChild(a);
});
