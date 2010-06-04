// ============================================================

function checkAcct() {
    var username = $("#username").val();
    var password = $("#password").val();
    var email = $("#email").val();
    var title = $("#title").val();

    var ok = true;
    if (!check("username")) { ok = false; }
    if (!check("password")) { ok = false; }
    if (!check("email")) { ok = false; }
    if (!check("title")) { ok = false; }
    if (!ok) {
	$("#error").html("All fields are required.");
	return false;
    } else {
	$("#error").html("");
    }

    $.get("/request-user.xqy", {
	username: username,
	password: password,
	email: email,
	title: title },
	   confirmCreate);

    return false;
}

function check(field) {
    if ($("#" + field).val() == "") {
	$("#s-" + field).css("color","red");
	return false;
    } else {
	$("#s-" + field).css("color","black");
	return true;
    }
}

function confirmCreate(data) {
    var username = $(data.getElementsByTagName("username")).text();
    var email = $(data.getElementsByTagName("email")).text();
    var token = $(data.getElementsByTagName("token")).text();
    var html = "???";

    if ($(data).children().get(0).nodeName == "error") {
        html = "An error occurred: " + $(data.getElementsByTagName("message")).text();
    } else {
        html = "<div>Congratulations. The account '" + username + "' has been "
	    + "created. Instructions for completing the process have been sent to "
	    + "your email address: " + email + "</div>";

        if (token != "") {
            // Debugging hack. If token is returned then we didn't send email
    	    html = "<div>Congratulations. The account '" + username + "' has been "
	        + "created. Complete the process by "
	        + "<a href='/create-user.xqy?token="+token+"'>clicking "
	        + "here</a>.</div>";
        }
    }

    $("#create").html(html)
}
