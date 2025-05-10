// تنظیم و راه اندازی select2
$(document).ready(function () {
  $(".select2").select2({
    dir: "rtl",
    allowClear: false,
    selectionCssClass: "never-selected",
    minimumResultsForSearch: 5,
  });
  $("#managerSelect").select2({
    placeholder: "       یک مدیر انتخاب کنید",
  });
  $("#teamSelect").select2({
    placeholder: "یک تیم انتخاب کنید",
  });
});

// بخش تغییر رادیو باتن های (بله، خیر) در قسمت اطلاعات تکمیلی
$(document).ready(function () {
  // دکمه بله ارشد دارد
  $("#hasSuperior_yes_image").on("click", function () {
    $("#hasSuperior_yes_input").prop("checked", true);
    $(this).attr("src", $(this).data("clicked"));
    $("#hasSuperior_no_image").attr(
      "src",
      $("#hasSuperior_no_image").data("default")
    );
  });
  // دکمه خیر ارشد دارد
  $("#hasSuperior_no_image").on("click", function () {
    $("#hasSuperior_no_input").prop("checked", true);
    $(this).attr("src", $(this).data("clicked"));
    $("#hasSuperior_yes_image").attr(
      "src",
      $("#hasSuperior_yes_image").data("default")
    );
  });
  // دکمه بله سطح دارد
  $("#hasLevel_yes_image").on("click", function () {
    $("#hasLevel_yes_input").prop("checked", true);
    $(this).attr("src", $(this).data("clicked"));
    $("#hasLevel_no_image").attr(
      "src",
      $("#hasLevel_no_image").data("default")
    );
  });
  // دکمه خیر سطح دارد
  $("#hasLevel_no_image").on("click", function () {
    $("#hasLevel_no_input").prop("checked", true);
    $(this).attr("src", $(this).data("clicked"));
    $("#hasLevel_yes_image").attr(
      "src",
      $("#hasLevel_yes_image").data("default")
    );
  });
});

// دکمه اضافه کردن تیم که هم آن را تشکیل میدهد و هم اضافه میکند، تکراری بودن آن هم چک میشود
$(document).ready(function () {
  $("#topSide_button").on("click", function () {
    let selectedTeam = $("#teamSelect option:selected");

    if (selectedTeam.val()) {
      const teamCard = createTeamCard(
        (teamCode = selectedTeam.attr("teamCode")),
        (teamName = selectedTeam.val()),
        (imageSrc = selectedTeam.data("image-src"))
      );
      if (isDuplicated(teamCard.attr("teamCode"))) {
        $.confirm({
          title: `❌ تیم انتخاب شده تکراری است`,
          content: `شما نمیتوانید تیم تکراری اضافه کنید`,
          type: "red",
          theme: "modern",
          columnClass: "medium",
          boxWidth: "400px",
          useBootstrap: false,
          buttons: {
            ok: {
              text: "باشه",
              btnClass: "btn-red",
            },
          },
        });
      } else {
        teamCard.attr("data-image-src", selectedTeam.data("image-src"));
        selectedTeam.remove();
        $("#showSelectedTeam_gridContainer")
          .append(teamCard)
          .css("display", "grid");
      }
    } else {
      $.confirm({
        title: `❌ تیم انتخاب نشده است`,
        content: `برای اضافه کردن تیم، باید اول آن را انتخاب کنید.`,
        type: "red",
        theme: "modern",
        columnClass: "medium",
        boxWidth: "400px",
        useBootstrap: false,
        buttons: {
          ok: {
            text: "باشه",
            btnClass: "btn-red",
          },
        },
      });
    }
  });
});

// دکمه سطل آشغال که با زدن آن دکمه، اطلاعات آن قسمت حذف میشود
$(document).ready(function () {
  // حذف اطلاعات تیم
  $(document).on("click", ".item-card_close", function () {
    const container = $("#showSelectedTeam_gridContainer");
    const teamCard = $(this).closest(".team-card");
    const teamCode = teamCard.attr("teamCode");
    const teamName = teamCard.find("p").text();
    const imageSrc = teamCard.data("image-src");

    teamCard.fadeOut("slow", function () {
      $(this).remove();

      if (container.children().length == 0) {
        container.css("display", "none");
      }
    });

    const teamOption = $("<option>")
      .attr({
        "data-image-src": imageSrc,
        teamCode: teamCode,
      })
      .text(teamName);

    $("#teamSelect").prepend(teamOption).trigger("change");
  });

  // حذف اطلاعات متن های شرایط احراز و شرح شغل
  $(document).on("click", ".textContainer_deleteIcon", function () {
    const textContainer = $(this).closest(".textCard");
    const textTitle = textContainer.find("p").text().trim();
    textContainer.slideUp("slow", function () {
      $(this).remove();
    });
  });
});

// دکمه مثبت برای اضافه کردن متن برای شرح شغل و شرایط احراز
$(document).ready(function () {
  // شرایط احراز
  $("#conditionsPlusIcon").click(function () {
    const parent = $(this).closest(".bottomSection_headerContainer");
    const textContainer = parent.siblings(".bottomSection_textArea");
    let textCard_title = $("#conditionsInput").val().trim();
    let isDuplicated = false;

    if (textCard_title == "") {
      $.confirm({
        title: `❌ باکس وارد کردن متن خالی است`,
        content: `شما نمیتوانید متن خالی اضافه کنید`,
        type: "red",
        theme: "modern",
        columnClass: "medium",
        boxWidth: "400px",
        useBootstrap: false,
        buttons: {
          ok: {
            text: "باشه",
            btnClass: "btn-red",
          },
        },
      });
    } else {
      textCard_title = normalize_persian(textCard_title);

      if (textContainer.children().length) {
        textContainer.children().each(function () {
          let existingText = $(this).find("p").text().trim();
          existingText = normalize_persian(existingText);
          if (existingText == textCard_title) {
            isDuplicated = true;
            return false;
          }
        });
      }

      if (isDuplicated) {
        $.confirm({
          title: `❌ متن انتخاب شده تکراری است`,
          content: `شما نمیتوانید متن تکراری اضافه کنید`,
          type: "red",
          theme: "modern",
          columnClass: "medium",
          boxWidth: "400px",
          useBootstrap: false,
          buttons: {
            ok: {
              text: "باشه",
              btnClass: "btn-red",
            },
          },
        });
      } else {
        let textCard = createTextCard(text = textCard_title, cardClass = "conditionsText");
        textCard
          .hide()
          .appendTo(textContainer)
          .fadeIn("slow", function () {
            $("#conditionsInput").val("");
          });
      }
    }
  });
  // شرح شغل
  $("#dutiesPlusIcon").click(function () {
    const parent = $(this).closest(".bottomSection_headerContainer");
    const textContainer = parent.siblings(".bottomSection_textArea");
    let textCard_title = $("#dutiesInput").val().trim();
    let isDuplicated = false;

    if (textCard_title == "") {
      $.confirm({
        title: `❌ باکس وارد کردن متن خالی است`,
        content: `شما نمیتوانید متن خالی اضافه کنید`,
        type: "red",
        theme: "modern",
        columnClass: "medium",
        boxWidth: "400px",
        useBootstrap: false,
        buttons: {
          ok: {
            text: "باشه",
            btnClass: "btn-red",
          },
        },
      });
    } else {
      textCard_title = normalize_persian(textCard_title);

      if (textContainer.children().length) {
        textContainer.children().each(function () {
          let existingText = $(this).find("p").text().trim();
          existingText = normalize_persian(existingText);
          if (existingText == textCard_title) {
            isDuplicated = true;
            return false;
          }
        });
      }

      if (isDuplicated) {
        $.confirm({
          title: `❌ متن انتخاب شده تکراری است`,
          content: `شما نمیتوانید متن تکراری اضافه کنید`,
          type: "red",
          theme: "modern",
          columnClass: "medium",
          boxWidth: "400px",
          useBootstrap: false,
          buttons: {
            ok: {
              text: "باشه",
              btnClass: "btn-red",
            },
          },
        });
      } else {
        let textCard = createTextCard(text = textCard_title, cardClass = "dutiesText");;
        textCard
          .hide()
          .appendTo(textContainer)
          .fadeIn("slow", function () {
            $("#dutiesInput").val("");
          });
      }
    }
  });
});

// محدود کردن اینپوت های متن
$(document).ready(function () {
  $(".bottomSection_input, #roleTitleInput").on("keypress", function (e) {
    const char = String.fromCharCode(e.which);

    const validRegex = /^[آ-یa-zA-Z0-9۰-۹ ]$/;

    if (!validRegex.test(char)) {
      e.preventDefault();

      $.alert({
        title: "⛔ کاراکتر نامعتبر",
        content: `فقط حروف فارسی، انگلیسی و اعداد مجاز هستند.`,
        type: "red",
        theme: "modern",
        boxWidth: "400px",
        useBootstrap: false,
        buttons: {
          ok: {
            text: "باشه",
            btnClass: "btn-red",
          },
        },
      });
    }
  });
});

// بخش سابمیت فرم و ارسال آن به سرور
$(document).ready(function () {
  $("#roleRequestForm").on("submit", function (event) {
    event.preventDefault();

    const validation = validateRoleRequestForm();

    if (validation.error) {
      $.alert({
        title: "❌ خطا در ورود اطلاعات",
        content: validation.messages.join("<br>"),
        type: "red",
        theme: "modern",
        boxWidth: "400px",
        useBootstrap: false,
        buttons: {
          ok: { text: "باشه", btnClass: "btn-red" },
        },
      });
    } else {
      let formData = {
        RoleTitle: $("#roleTitleInput").val().trim(),
        RoleManager: $("#managerSelect").val(),
        HasLevel: $("#hasLevel_yes_input").is(":checked"),
        HasSuperior: $("#hasSuperior_yes_input").is(":checked"),
        AllowedTeams: [],
        Conditions: [],
        Duties: [],
      };

      // مقدار دهی به allowedTeams به ازای هر input
      $(".item-card_input").each(function () {
        let teamCode = $(this).attr("teamCode");
        let roleCount = $(this).val();
        formData.AllowedTeams.push({
          TeamCode: teamCode,
          RoleCount: roleCount,
        });
      });

      // وارد کردن متن های شرایط احراز
      $(".conditionsText").each(function () {
        let text = $(this).find("p").text().trim();
        text = normalize_persian(text);
        formData.Conditions.push(text)
      });

      // وارد کردن متن های شرح شغل 
      $(".dutiesText").each(function () {
        let text = $(this).find("p").text().trim();
        text = normalize_persian(text);
        formData.Duties.push(text)
      });

      $.ajax({
        url: window.location.href,
        type: "POST",
        data: JSON.stringify(formData),
        contentType: "application/json",
        headers: {
          "X-CSRFToken": $("meta[name='csrf_holder']").attr("content"),
          "Content-Type": "application/json",
        },
        beforeSend: function () {
          $.LoadingOverlay("show");
        },
        complete: function () {
          $.LoadingOverlay("hide");
        },
        success: function (response) {
          let error = response.Error;
          $.confirm({
            title: error ? "❌ خطا" : "✅ موفقیت",
            content: response.Message,
            type: error ? "red" : "green",
            theme: "modern",
            columnClass: "medium",
            boxWidth: "400px",
            useBootstrap: false,
            buttons: {
              ok: {
                text: "باشه",
                btnClass: error ? "btn-red" : "btn-green",
                action: function () {
                  $.LoadingOverlay("show");
                  window.location.reload();
                },
              },
            },
          });
        },
        error: function (error) {
          $.confirm({
            title: "❌ خطا در ارتباط",
            content: "خطایی در ارتباط با سرور رخ داده است.",
            type: "red",
            theme: "modern",
            columnClass: "medium",
            boxWidth: "400px",
            useBootstrap: false,
            buttons: {
              ok: {
                text: "باشه",
                btnClass: "btn-red",
              },
            },
          });
        },
      });
    }

  });
});

// ------------------------------------ FUNCTIONS ------------------------------------ //

// ایجاد تیم و ارسال آن برای نشان دادن
function createTeamCard(teamCode = null, teamName = null, imageSrc = null) {
  if (teamCode && teamName && imageSrc) {
    const teamCard = $("<div>").attr({
      class: "team-card",
      teamCode: teamCode,
    });
    const itemCard_iconGroup = $("<div>").attr("class", "item-card_icon-group");
    const itemCard_quantity = $("<div>").attr("class", "item-card_quantity");
    const itemCard_close = $("<i>").attr({
      class: "fa-solid fa-trash-can item-card_close",
    });

    const itemCard_icon = $("<img>").attr({
      src: `${imageSrc}${teamCode}.png`,
      alt: "Team Icon",
      class: "item-card_icon",
    });
    const team_name = $("<p>").attr("class", "subHeaderTitle").text(teamName);

    const inputLabel = $("<label>")
      .attr({
        for: "roleNumberInput",
        class: "subHeaderTitle",
      })
      .text("تعداد :");
    const itemCard_input = $("<input>").attr({
      id: "roleNumberInput",
      type: "number",
      min: "1",
      max: "100",
      value: "1",
      class: "item-card_input",
      teamCode: teamCode,
    });

    itemCard_iconGroup.append(itemCard_icon, team_name);
    itemCard_quantity.append(inputLabel, itemCard_input);
    teamCard.append(itemCard_iconGroup, itemCard_quantity, itemCard_close);
    return teamCard;
  } else {
    $.confirm({
      title: `❌ کد تیم انتخاب نشده است`,
      content: `مشکلی در انتخاب تیم پیش آمده است، دوباره امتحان کنید`,
      type: "red",
      theme: "modern",
      columnClass: "medium",
      boxWidth: "400px",
      useBootstrap: false,
      buttons: {
        ok: {
          text: "باشه",
          btnClass: "btn-red",
        },
      },
    });
  }
}

// ایجاد متن برای شرح شغل و شرایط احراز
function createTextCard(text, cardClass) {
  const textCard = $("<div>").attr({ class: `textCard ${cardClass}` });
  const textCard_title = $("<p>").text(text);
  const textCard_deleteIcon = $("<i>").attr(
    "class",
    "fa-solid fa-trash-can textContainer_deleteIcon"
  );

  textCard.append(textCard_title, textCard_deleteIcon);
  return textCard;
}

// چک کردن تیم ها برای جلوگیری از تکراری بودن آن
function isDuplicated(teamCode) {
  let isDuplicate = false;
  $("#showSelectedTeam_gridContainer")
    .children(".team-card")
    .each(function () {
      existingTeamCode = $(this).attr("teamCode");
      if (existingTeamCode == teamCode) {
        isDuplicate = true;
        return true;
      }
    });
  return isDuplicate;
}

// حروف فارسی که با کیبورد عربی نوشته شده باشه رو درست میکنه
function normalize_persian(text) {
  return text
    .replace(/ي/g, "ی")
    .replace(/ك/g, "ک")
    .replace(/\u200c/g, " ");
}

// اعتبار سنجی فرم
function validateRoleRequestForm() {
  const result = {
    error: false,
    messages: [],
  };

  // 1. عنوان سمت
  const title = $.trim($("#roleTitleInput").val());
  if (!title) {
    result.error = true;
    result.messages.push("📌 عنوان سمت را وارد کنید.");
  }

  // 2. مدیر مربوطه (Select2)
  const managerVal = $("#managerSelect").val();
  if (!managerVal) {
    result.error = true;
    result.messages.push("📌 مدیر مربوطه را انتخاب کنید.");
  }

  // 3. حداقل یک تیم
  if ($("#showSelectedTeam_gridContainer").children().length == 0) {
    result.error = true;
    result.messages.push("📌 حداقل یک تیم اضافه کنید.");
  }

  // 4. شرایط احراز
  if ($(".bottomSection_textArea").eq(0).children().length === 0) {
    result.error = true;
    result.messages.push("📌 حداقل یک «شرط احراز» وارد کنید.");
  }

  // 5. شرح شغل
  if ($(".bottomSection_textArea").eq(1).children().length === 0) {
    result.error = true;
    result.messages.push("📌 حداقل یک «شرح شغل» وارد کنید.");
  }

  // اگر هیچ خطایی نداشتیم، پیام موفقیت‌آمیز بذار
  if (!result.error) {
    result.messages.push("✅ همه موارد با موفقیت تکمیل شدند.");
  }

  return result;
}
