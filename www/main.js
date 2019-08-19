$.ajax({
  method: 'put',
  url: 'http://localhost:8065',
  contentType: 'application/json',
  dataType: 'json',
  data: JSON.stringify({
    title: 'test',
    page: 2,
    limit: 10
  }),
}).then(result => {
  $('.result').html(JSON.stringify(result));
})


// var url = 'http://localhost:8065';
// var xhr = new XMLHttpRequest();
// xhr.open('PUT', url, true);
// xhr.setRequestHeader('X-Custom-Header', 'value');
// xhr.send();