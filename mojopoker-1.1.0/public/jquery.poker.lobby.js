;
(function($, window, document) {
    $.widget("poker.lobby", {
        options: {
            widthToHeight: 4 / 3,
            epochDiff: 0,
            inchan: {},
            colData: {
                1: ["Id", "int"],
                2: ["Stakes", "string"],
                3: ["Limit", "string"],
                4: ["Seats", "int"],
                5: ["Plrs", "string"],
                6: ["Wait", "int"],
                7: ["Avg Pot", "int"],
                8: ["Plrs/Flop", "int"],
                9: ["H/hr", "int"],
                10: ["Start", "int"],
                11: ["Game", "string"],
                12: ["Buy-In", "int"],
                13: ["State", "string"],
                14: ["Enrolled", "int"],
                15: ["Table", "int"],
                16: ["Speed", "string"],
                17: ["Login", "string"],
                18: ["Name", "string"],
                19: ["Location", "string"],
                20: ["Player", "string"],
                21: ["Chips", "int"],
                22: ["Seat", "int"],
                23: ["Block", "int"],
                24: ["Player Pool", "int"],
                25: ["#", "int"],
                26: ["Profit", "string"]
            },
            ringCols: [25, 11, 2, 3, 4, 5, 7, 8, 9],
            leaderCols: [25, 20, 26, 21],
            socialCols: [17, 18, 19],
            hydraCols: [1, 11, 2, 3, 4, 24],
            loginData: {},
            ringData: {},
            fastData: {},
            gameState: {
                0: "Closed",
                1: "Registering",
                2: "Late Reg.",
                3: "Full",
                4: "Playing",
                6: "Complete"
            },
            gameTabs: {
                all: ["All", 1],
                dealers: ["Dealer's Choice", 1],
                holdem: ["Hold'em", 1],
                holdemjokers: ["Hold'em (Jokers)", 1],
                pineapple: ["Pineapple", 1],
                crazypine: ["Crazy Pineapple", 1],
                omaha: ["Omaha", 1],
                omahahilo: ["Omaha Hi-Lo", 1],
                omahafive: ["5 Card Omaha", 2],
                omahafivehilo: ["5 Card Omaha Hi-Lo", 2],
                courcheval: ["Courcheval", 2],
                courchevalhilo: ["Courcheval Hi-Lo", 2],
                fivedraw: ["5 Card Draw", 2],
                drawjokers: ["5 Card Draw (Jokers)", 2],
                drawdeuces: ["5 Card Draw (Deuces)", 3],
                singledraw27: ["2-7 Single Draw", 3],
                tripledraw27: ["2-7 Triple Draw", 3],
                singledrawa5: ["A-5 Single Draw", 3],
                tripledrawa5: ["A-5 Triple Draw", 3],
                sevenstud: ["7 Card Stud", 3],
                razz: ["Razz", 3],
                sevenstudhilo: ["7 Card Stud Hi-Lo", 4],
                sevenstudjokers: ["7 Card Stud (Jokers)", 4],
                highchicago: ["High Chicago", 4],
                ftq: ["Follow the Queen", 4],
                bitch: ["The Bitch", 4],
                badugi: ["Badugi", 4],
                badacey: ["Badacey", 4],
                badeucy: ["Badeucy", 4]
            }
        },
        _create: function() {
            var v = this,
                e = v.options,
                f = v.element;

            clearInterval(e.clockTimer);

            $("#lobby-name").hide();
            $("#lobby-chips").hide();
            $("#main-chat").empty();

            // leaderboard table
            $("#lobby-leader").append(v._buildTable(e.leaderCols));

            // logout button
            $("#lobby-logout").click(function() {
                $("#poker-main").main("logout")
            });

            // help button
            $("#lobby-head2").on("click", function() {
                $( "#lobby-help" ).dialog({
                   modal: true,
                   buttons: {
                      Ok: function() {
                         $( this ).dialog( "close" );
                      }
                   }
                });
            });

            // build game tabs
            $("#ring-info").append(v._buildTable(e.ringCols));

            // chat form
            var si = $("#social-input");
            $("#social-form").submit(function(m) {
                m.preventDefault();
                var y = /^[\w\s\.\,\?!@#\$%^&\*\(\)_]{0,90}$/;
                if (y.test(si.val())) {
                    $("#poker-main").main("write_channel", {
                        channel: 'main',
                        message: si.val()
                    })
                }
                si.val("")
            });

            // game tabs
            $.each(e.gameTabs, function(o, m) {
                f.find("#game-tabs" + m[1]).append($("<button />").attr({
                    id: o + "-tab",
                    info: o
                }).addClass("lobby-tab").html(m[0]))
            });

            // clicking behavior
            f.on("click", "#tabs .lobby-tab", function() {
                    var m = $(this);
                    f.find("#tabs > [type=" + m.parent().attr("type") + "] .lobby-tab.select").removeClass("select");
                    m.addClass("select")
                })
                .on("click", "#tabs > [type=game] .lobby-tab", function() {
                    var y = $(this).attr("info");
                    var o = f.find(".tab-info.games tbody tr");
                    if (y == "all") {
                        o.show()
                    } else {
                        o.filter("[game_class=" + y + "]").show();
                        o.filter("[game_class!=" + y + "]").hide()
                    }

                })

                // highlighter 
                .on("click", ".tab-info tbody tr", function() {
                    var m = $(this);
                    m.siblings().removeClass("select");
                    m.addClass("select")
                })
                .on("click", "#ring-info tbody tr", function() {
                    var m = $(this).attr("table_id");
                    $("#poker-main").main("watch_table", {
                        table_id: m
                    })
                })
                // buton hoover
                .on("mouseenter", "button.lobby-tab", function() {
                    $(this).addClass("tab-hover")
                })
                .on("mouseleave", "button.lobby-tab", function() {
                    $(this).removeClass("tab-hover")
                });
            $(window).resize(function() {
                v.resizeLobby()
            });
            v.resizeLobby();
            $("#social-input").focus();
        },
        watch_table_res: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            $("#table-ring").append($("<div />").attr("id", "tring" + f.table_id).table_ring(f))
        },
        _destroy: function() {},
        /*
                _buildRing: function(i) {
                    var q = this,
                        e = q.options,
                        f = q.element;
                    var m = f.find("#ring-box").attr("tid", i);
                    var l = e.ringData[i];
                    var r = l.small_blind + "/" + l.big_blind;
                    var j = l.game_class == "dealers" ? "--" : l.limit;
                    var p = e.gameTabs[l.game_class][0];
                    m.find(".box-header").html("(" + i + ") " + r + " " + j + " " + p);
                    var h = m.find("table tbody");
                    m.find(".box-footer").attr("tid", i);
                    h.children().remove();
                    var n = "";
                    $.each(e.ringData[i].plr_map, function(o, g) {
                        s = ++o;
                        n += "<tr><td>" + s + "</td><td>" + e.loginData[g.login_id].username + "</td><td>" + g.chips + "</td></tr>"
                    });
                    h.html(n);
                    m.show()
                },
        */
        destroy: function() {},
        register_res: function(g) {
            var f = this;
            var e;
            if (g.success) {
                f.login_success(g)
            } 
        },
        update_profile_res: function(g) {
            var f = this;
            var e;
            if (g.success) {
                f._update_lobby(g)
            }
        },
        _buildTable: function(h) {
            var e = this,
                i = e.options,
                g = e.element;
            var f = "";
            $.each(h, function(m, j) {
                var o = i.colData[j][0];
                var l = i.colData[j][1];
                f += '<th data-sort-dir="asc" data-sort="' + l + '">' + o + "</th>"
            });
            return $("<div/>").addClass("table-box").append($("<table />").append($("<thead />").append($("<tr>").html(f)), $("<tbody />")).stupidtable().bind("aftertablesort", function(l, n) {
                $this = $(this);
                //$this.find("tbody tr:visible:first").trigger("click");
                var j = $this.find("th");
                j.find(".arro").remove();
                var m = n.direction === "asc" ? "↑" : "↓";
                j.eq(n.column).append('<span class="arro">' + m + "</span>")
            }))
        },
        resizeLobby: function(g) {
            var h = this.options,
                //e = this.element,
                newWidth = window.innerWidth * .9,
                newHeight = window.innerHeight * .9,
                newWidthToHeight = newWidth / newHeight;

            if (newWidthToHeight > h.widthToHeight) {
                newWidth = newHeight * h.widthToHeight;
            } else { // window height is too high relative to desired game height
                newHeight = newWidth / h.widthToHeight;
            }
            this.element.css({
                height: newHeight + "px",
                width: newWidth + "px",
                marginTop: (-newHeight / 2) + "px",
                marginLeft: (-newWidth / 2) + "px",
                fontSize: (newWidth / 680) + "em"
            });
        },
        guest_login: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            e._update_lobby(f);

            h.epochDiff = (new Date).getTime() - (f.epoch * 1000);
            h.myData = {
                login_id: f.login_id,
                username: f.username,
                chips: f.chips
            };

            //$("#lobby-name").html(h.myData.username);
           
            e._reset_timer(f.timer);

            e._check_login_status();

        },
        _reset_timer: function(t) {
            var e = this,
                h = e.options;

            clearInterval(h.clockTimer); 
            h.distance = t;

            var counter = $("#lobby-countdown > span");

            h.clockTimer = setInterval(function() {
                h.distance -= 1;
                //var days = Math.floor(h.distance / (86400));
                var hours = Math.floor((h.distance % (86400)) / (3600));
                var minutes = Math.floor((h.distance % 3600) / 60);
                var seconds = Math.floor(h.distance % 60);

                counter.html(hours + 'h ' + minutes + 'm ' + seconds + 's');

                if (h.distance <= 0) {
                    e._reset_timer(604800);
                }
            }, 1000);

        },
        _check_login_status: function() {
            FB.getLoginStatus(function(res) {
                if (res.status == 'connected') {
                    $("#poker-main").main("authorize", res);
                } else {
                   $("#lobby-loginout").removeClass("logout").addClass("login").off('click').click(function() {
                      FB.login(function(r) {
                         $("#poker-main").main("authorize", r);
                      });
                   });
                }
            });
        },
        modal_message: function(t, title) {
            var h = this;

            title |= 'Attention';
            $("#modal-text").empty().text(t);
            $("#modal-box").dialog({
                title: title,
                position: {
                    my: "center",
                    at: "center",
                    of: window
                },
                modal: true,
                buttons: [{
                    text: "OK",
                    click: function() {
                        $("#modal-text").empty();
                        $(this).dialog("close");
                    }
                }]
            });
        },
        login_success: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            //this.options.myData = f;
            $("#lobby-name").show();
            $("#lobby-chips").show();
            e._update_lobby(f)
            //alert(JSON.stringify(f));
            //e._buildCashier();
            //g.find("#lobby-login").html("Cashier").off("click").click(function() {
            //    $("#poker-main").main("login_info")
            //});
            //$("#lobby-name").html(h.myData.username)
        },
        login_res: function(f) {
            if (f.success) {
                this.login_success(f)
                //e.modal_message("Success! Welcome " + f.username + "!");
            }
        },
        authorize_res: function(f) {
            //alert(JSON.stringify(f));
            var t = this,
                o = t.options,
                e = t.element;
            if (f.success) {
                //$.extend(o.myData, f);
                //$("#lobby-username").html(h.myData.name);

                $("#lobby-loginout").removeClass("login").addClass("logout").off('click').click(function() {
                    FB.logout(function() {
                       $("#poker-main").main("logout");
                       $("#lobby-cashier").hide();
                    });
                });
                $("#lobby-cashier").off('click').click(function() {
                   //alert('cashier');
                   $("#poker-main").main("fetch_cashier");
                }).show();

                //FB.api('/111374336789924', {
                FB.api('/me', {
                   fields: "first_name,last_name,picture"
                    //fields: "id,name,picture"
                }, function(re) {
                   $("#poker-main").main("update_profile", re);
                });

            } else {
                //h.modal_message('Login and tyr again', 'Bad Credentials');
            }
        },
        login_update: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            e._update_lobby(f);
            //h.myData = f
        },
        login_info_res: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            if (f.success) {
                e._update_lobby(f);
                // h.myData = f;
                //$("#cashier").show()
            } 
        },
        join_channel_res: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            h.inchan[f.channel] = f.success ? true : false
        },
        unjoin_channel_res: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            h.inchan[f.channel] = f.success ? false : true
        },
        notify_message: function(g) {
            var f = this,
                l = f.options,
                h = f.element;

            /* don't block
                        if (l.loginData[g.from] && l.loginData[g.from]["block"]) {
                            return
                        }
            */

            //alert(JSON.stringify(g));
            //var info = f.login_info[g.from];
            //var color = (info && info.color) ? info.color : 'black';
            var color = 'black';

            var e = $("#" + g.channel + "-chat");

            // keep chat window tidy

            //if (msgs.length > 19) {
            //   msgs.first().remove();
            //}

/*
            e.append($("<div />").addClass("chat-msg").append( $("<div />").addClass("chat-pic").css("background-image", "url(" + g.profile_pic + ")"), $("<div />").addClass("chat-content").html(g.username + ': ' + g.message)));

*/
            e.append($("<div />").addClass("chat-msg").append( $("<span />").addClass("chat-pic").css("background-image", "url(" + g.profile_pic+ ")"), $("<span />").addClass("chat-content").html(g.username + ': ' + g.message)));


// , $("<span />").addClass("chat-handle").html(g.username + ': ').css("color", color))));


/*
            e.append($("<div />").addClass("chat-msg").append( $("<div />").addClass("chat-pic").css("background-image", "url(" + g.profile_pic+ ")"), $("<span />").addClass("chat-content").html(g.username + ': ' + g.message)));
*/

            e.animate({
                scrollTop: e[0].scrollHeight
            })
        },
        notify_leaders: function(f) {
            //alert(JSON.stringify(f));
            var table = $("#lobby-leader tbody");
            table.empty();
            $.each(f.leaders, function(index, obj) {
                var count = 1;
                var row = $("<tr >").append("<td >").html(index + 1);
                $.each(obj, function(key, value) {
                    //row.append($("<td >").html(value));
                    col = $("<td >").html(value);
                    if (count == 2) {
                       if (value < 0) {
                          col.addClass("red");
                          col.html(value + '%'); 
                       } else {
                          col.addClass("green");
                          col.html('+' + value + '%'); 
                       }
             
                    } else {
                       col.html(value);
                    }
                    row.append(col);
                    count++;
                });
                table.append(row);
            });
        },
        notify_login: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            this.notify_logout(f);
            f.color = "rgb(" + Math.floor(Math.random() * 256) + "," + Math.floor(Math.random() * 256) + "," + Math.floor(Math.random() * 256) + ")";
            h.loginData[f.login_id] = f;
            /*
                        g.find("#social-info .table-box tbody").append($("<tr />").attr("login_id", f.login_id).append($("<td />").html(f.username), $("<td />").addClass("block yes").click(function() {
                            var i = $(this);
                            i.toggleClass("yes");
                            if (i.hasClass("yes")) {
                                h.loginData[f.login_id]["block"] = true;
                                i.html("Yes")
                            } else {
                                h.loginData[f.login_id]["block"] = false;
                                i.html("No")
                            }
                        }).click()))
            */
        },
        notify_logout: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            delete h.loginData[f.login_id];
            g.find("#social-info .table-box tbody tr[login_id=" + f.login_id + "]").remove()
        },
        ring_snap: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            $.each(f, function(j, l) {
                h.ringData[l.table_id] = l
            });
            e._build_ring_tab()
        },
        _build_ring_tab: function() {
            var e = this,
                h = e.options,
                g = e.element;
            var f = g.find("#ring-info tbody");
            f.empty();
            $.each(h.ringData, function(l, j) {
                var m = j.small_blind + "/" + j.big_blind;
                var i = j.game_class == "dealers" ? "--" : j.limit;
                $("<tr />").attr({
                    id: "lring" + l,
                    table_id: j.table_id,
                    //did: j.director_id,
                    game_class: j.game_class
                }).addClass("lring").append($("<td />").addClass("table-id").html(j.table_id), $("<td />").html(h.gameTabs[j.game_class][0]), $("<td />").addClass().html(m), $("<td />").addClass().html(i), $("<td />").addClass().html(j.chair_count), $("<td />").addClass("plr-count"), $("<td />").addClass("avg-pot"), $("<td />").addClass("plrs-flop"), $("<td />").addClass("hhr")).appendTo(f);
                e._update_ring_tab(j);
            });
            // g.find("#play-tab").trigger("click"));
            g.find("#all-tab").trigger("click");
            g.find("#ring-info thead th:eq(5)").trigger("click");
        },
        notify_create_ring: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            h.ringData[f.table_id] = f;
            e._build_ring_tab()
        },
        notify_destroy_ring: function(e) {
            delete this.options.ringData[e.table_id];
            this.element.find("#lring" + e.table_id).remove()
        },
        notify_lr_update: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            $.extend(h.ringData[f.table_id], f);
            e._update_ring_tab(f)
        },
        _update_lobby: function(g) {
            var t = this,
                o = t.options;

            $.extend(o.myData, g);

            var e = {
                chips: function(l) {
                    $("#lobby-chips span").html(l);
                },
                username: function(l) {
                    $("#lobby-name").html(l);
                }
            };
            $.each(g, function(l, m) {
                if (l in e) {
                    e[l](m)
                }
            })
        },
        _update_ring_tab: function(g) {
            var f = this,
                j = f.options,
                i = f.element;
            var h = i.find("#lring" + g.table_id);
            /*
                        if (i.find("#ring-box").attr("tid") == g.table_id) {
                            h.trigger("click")
                        }
            */
            var e = {
                avg_pot: function(l) {
                    h.find(".avg-pot").html(l)
                },
                plrs_flop: function(l) {
                    h.find(".plrs-flop").html(l)
                },
                hhr: function(l) {
                    h.find(".hhr").html(l)
                },
                plr_map: function(m) {
                    var n = h.find(".plr-count");
                    var l = 0;
                    for (k in m) {
                        l++
                    }
                    n.html(l)
                }
            };
            $.each(g, function(l, m) {
                if (l in e) {
                    e[l](m)
                }
            })
        },
        _msgHandler: function(g, f) {
            var e = {};
            if (g in e) {
                e[g](f)
            }
        },
        _setOption: function(g, i) {
            var f = this,
                j = f.options,
                h = f.element;
            var e = {};
            if (g in e) {
                j[g] = i;
                e[g](i)
            }
        }
    })
})(jQuery, window, document);
