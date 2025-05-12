
    jQuery(document).ready(function($){
        $("#fake_user_combo").select2();
        $("#fake_user_combo").on('select2:select',function(e){
            $(".div-loader-base").show()
            var data = e.params.data;
            var token = $("[name='input_token']").val();
            var csrf = $("[name='csrfmiddlewaretoken']").val();
            var next_url = location.protocol + '//' + location.host + location.pathname;
            $.post(`/Portal/GenerateLinkFakeUser/`,{'change_to_username':data.id,'token':token,'csrfmiddlewaretoken':csrf,'next_url':next_url},function(data){
                if(data.state == "ok"){
                    window.location.href = data.url;
                }
            })
        });

        $("#exit_current_login").on('click',function(){
            $(".div-loader-base").show()
            var next_url = location.protocol + '//' + location.host + location.pathname;
            var url = `http://eit-app:5000/Auth/?next=${next_url}`;
            window.location.href = url;
        });

        setTimeout(checkImageNotExists,500);
        function checkImageNotExists(){
            var img = document.querySelector(".img-profile");
            var src = img.getAttribute("default-src");//(img.getAttribute("gender") == "m") ? img.getAttribute("default-src-m") : img.getAttribute("default-src-f");
            if(img.naturalWidth ==0 ) {
                img.setAttribute("src", src);
            }
        }

    })