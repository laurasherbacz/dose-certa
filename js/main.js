// Validação de formulários (Bootstrap)
document.querySelectorAll('form.needs-validation').forEach(function(f){
  f.addEventListener('submit',function(e){
    if(!f.checkValidity()){e.preventDefault();e.stopPropagation();}
    f.classList.add('was-validated');
  });
});
