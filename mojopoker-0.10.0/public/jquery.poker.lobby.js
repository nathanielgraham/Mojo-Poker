(function(c, b, a, d) {
    c.widget("poker.lobby", {
        options: {
            heightToWidth: 9 / 16,
            windowRatio: 15 / 16,
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
                24: ["Player Pool", "int"]
            },
            ringCols: [1, 11, 2, 3, 4, 5, 7, 8, 9],
            tourCols: [1, 10, 11, 12, 13, 14],
            socialCols: [17, 18, 19],
            hydraCols: [1, 11, 2, 3, 4, 24],
            loginData: {},
            ringData: {},
            tourData: {},
            fastData: {},
            gameState: {
                0: "Closed",
                1: "Registering",
                2: "Late Reg.",
                3: "Full",
                4: "Playing",
                6: "Complete"
            },
            tourClasses: {
                1: "Freezeout",
                2: "Shootout",
                3: "Fifty50",
                4: "Bounty"
            },
            gameTabs: {
                dealers: ["Dealer's Choice", 1],
                holdem: ["Hold'em", 1],
                holdemjokers: ["Hold'em (Jokers Wild)", 1],
                pineapple: ["Pineapple", 1],
                crazypine: ["Crazy Pineapple", 1],
                omaha: ["Omaha", 1],
                omahahilo: ["Omaha Hi-Lo", 1],
                omahafive: ["5 Card Omaha", 2],
                omahafivehilo: ["5 Card Omaha Hi-Lo", 2],
                courcheval: ["Courcheval", 2],
                courchevalhilo: ["Courcheval Hi-Lo", 2],
                fivedraw: ["5 Card Draw", 2],
                drawjokers: ["5 Card Draw (Jokers Wild)", 2],
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
            var q = c("<div />").attr("id", "tabs");
            var u = c("<div />").attr({
                id: "main-tabs",
                type: "main"
            });
            var l = c("<div />").attr({
                id: "game-tabs1",
                type: "game"
            });
            var j = c("<div />").attr({
                id: "game-tabs2",
                type: "game"
            });
            var i = c("<div />").attr({
                id: "game-tabs3",
                type: "game"
            });
            var h = c("<div />").attr({
                id: "game-tabs4",
                type: "game"
            });
            var n = c("<div />").attr({
                id: "money-tabs",
                type: "money"
            });
            var t = c("<div />").attr({
                id: "social-tabs",
                type: "social"
            });
            var r = c("<div />").attr({
                id: "about-tabs",
                type: "about"
            });
            var x = c("<div />").attr("id", "ring-box").addClass("main-box").append(c("<div />").addClass("box-header"), v._buildTable([22, 20, 21]), c("<button />").addClass("box-footer").html("Go to Table").click(function() {
                c("#poker-main").main("watch_table", {
                    table_id: c(this).attr("tid")
                })
            }));
            var p = c("<div />").attr("id", "hydra-box").addClass("main-box").append(c("<div />").addClass("box-header"), c("<button />").addClass("box-footer").html("Join Pool").click(function() {
                c("#poker-main").main("hydra_info", {
                    hydra_id: c(this).attr("tid")
                })
            }));
            var w = c("<input />").attr({
                id: "social-input",
                type: "text",
                maxlength: 30
            });
            var g = f.addClass("ui-widget").append(c("<div />").attr("id", "lobby-header"), c("<div />").attr("id", "lobby-logo"), c("<div />").attr("id", "lobby-clock"), c("<div/>").attr("id", "welcome"), c("<button />)").attr("id", "lobby-red").html("Log-Inn").click(function() {
                c("#login-box").show();
                c("#login-name").focus()
            }), c("<div />").attr("id", "login-box").addClass("lobby-modal"), c("<div />").attr("id", "modal-box").addClass("lobby-modal"), c("<div />").attr("id", "new-account").addClass("lobby-modal"), x, c("<div />").attr("id", "ring-info").addClass("tab-info games").append(v._buildTable(e.ringCols)), c("<div />").attr("id", "social-info").addClass("tab-info").append(v._buildTable([18, 23]), c("<div />").attr("id", "help-chat").addClass("social-chat"), c("<div />").attr("id", "strat-chat").addClass("social-chat"), c("<div />").attr("id", "unmod-chat").addClass("social-chat"), c("<form />").attr("id", "social-form").append(w).submit(function(m) {
                m.preventDefault();
                var y = /^[\w\s\.\,\?!@#\$%^&\*\(\)_]{0,30}$/;
                if (y.test(w.val())) {
                    var o = f.find("#social-tabs .lobby-tab.select").attr("info");
                    c("#poker-main").main("write_channel", {
                        channel: o,
                        message: w.val()
                    })
                }
                w.val("")
            })), c("<div />").attr("id", "about-info").addClass("tab-info").append(c("<iframe />").attr({
                id: "soft-info",
                src: "faq.html"
            }).addClass("about-box"), c("<iframe />").attr({
                id: "contact-info",
                src: "contact.html"
            }).addClass("about-box")), q.append(u.append(c("<button />").attr({
                id: "ring-tab",
                info: "ring"
            }).addClass("lobby-tab").html("Ring").click(function() {
                x.show();
                p.hide();
                l.show();
                j.show();
                i.show();
                h.show();
                n.attr("info", "ring").show();
                t.hide();
                r.hide()
            }), c("<button />").attr({
                id: "social-tab",
                info: "social"
            }).addClass("lobby-tab").html("Social").click(function() {
                x.hide();
                p.hide();
                l.hide();
                j.hide();
                i.hide();
                h.hide();
                n.hide();
                r.hide();
                t.show()
            }), c("<button />").attr({
                id: "about-tab",
                info: "about"
            }).addClass("lobby-tab").html("About").click(function() {
                x.hide();
                p.hide();
                l.hide();
                j.hide();
                i.hide();
                h.hide();
                n.hide();
                t.hide();
                r.show()
            })), l.append(c("<button />").attr({
                id: "all-tab",
                info: "all"
            }).addClass("lobby-tab").html("All")), j, i, h, n, t, r));
            c.each(e.gameTabs, function(o, m) {
                f.find("#game-tabs" + m[1]).append(c("<button />").attr({
                    id: o + "-tab",
                    info: o
                }).addClass("lobby-tab").html(m[0]))
            });
            n.append(c("<button />").attr({
                id: "play-tab",
                info: "play"
            }).addClass("lobby-tab").html("Play Money"), c("<button />").attr({
                id: "real-tab",
                info: "real"
            }).addClass("lobby-tab").html("Other Money"));
            t.append(c("<button />").attr({
                id: "strat-tab",
                info: "strat"
            }).addClass("lobby-tab").html("Main Chat"), c("<button />").attr({
                id: "unmod-tab",
                info: "unmod"
            }).addClass("lobby-tab").html("Unmoderated"), c("<button />").attr({
                id: "help-tab",
                info: "help"
            }).addClass("lobby-tab").html("Help"));
            r.append(c("<button />").attr({
                id: "soft-tab",
                info: "soft"
            }).addClass("lobby-tab").html("FAQ"), c("<button />").attr({
                id: "contact-tab",
                info: "contact"
            }).addClass("lobby-tab").html("Contact"));
            g.on("click", "#tabs .lobby-tab", function() {
                var m = c(this);
                f.find("#tabs > [type=" + m.parent().attr("type") + "] .lobby-tab.select").removeClass("select");
                m.addClass("select")
            }).on("click", "#main-tabs .lobby-tab", function() {
                var m = c(this).attr("info");
                f.find(".tab-info.select").removeClass("select").hide();
                var m = f.find("#" + m + "-info");
                m.addClass("select").show()
            }).on("click", "#tour-tab", function() {
                f.find(".tab-info.games.select tbody tr").show();
                var m = f.find("#money-tabs .lobby-tab.select").attr("info");
                v._filter_money(m)
            }).on("click", "#ring-tab", function() {
                f.find("#tabs > [type=game] .lobby-tab.select").trigger("click")
            }).on("click", "#tabs > [type=game] .lobby-tab", function() {
                var y = c(this).attr("info");
                var o = f.find(".tab-info.games.select tbody tr");
                if (y == "all") {
                    o.show()
                } else {
                    o.filter("[game_class=" + y + "]").show();
                    o.filter("[game_class!=" + y + "]").hide()
                }
                var m = f.find("#money-tabs .lobby-tab.select").attr("info");
                v._filter_money(m)
            }).on("click", "#money-tabs .lobby-tab", function() {
                $this = c(this);
                $this.addClass("select");
                var m = $this.attr("info");
                f.find("#main-tabs .lobby-tab.select").trigger("click");
                v._filter_money(m)
            }).on("click", "#social-tabs .lobby-tab", function() {
                var m = c(this).attr("info");
                f.find("#social-info .social-chat").hide();
                f.find("#" + m + "-chat").show();
                f.find("#social-input").focus();
                if (!e.inchan[m]) {
                    c("#poker-main").main("join_channel", {
                        channel: m
                    })
                }
            }).on("click", "#about-tabs .lobby-tab", function() {
                var m = c(this).attr("info");
                f.find("#about-info .about-box").hide();
                f.find("#about-info #" + m + "-info").show()
            }).on("click", ".tab-info tbody tr", function() {
                var m = c(this);
                m.siblings().removeClass("select");
                m.addClass("select")
            }).on("click", "#ring-info tbody tr", function() {
                var m = c(this).attr("table_id");
                v._buildRing(m)
            }).on("dblclick", "#ring-info tbody tr", function() {
                var m = c(this).attr("table_id");
                c("#poker-main").main("watch_table", {
                    table_id: m
                })
            }).on("click", "#social-tab", function() {
                f.find("#social-input").focus()
            }).on("dblclick", "#tour-info tbody tr", function() {
                var m = c(this).attr("tour_id");
                c("#poker-main").main("watch_tour", {
                    tour_id: m
                })
            }).on("mouseenter", "button.lobby-tab", function() {
                c(this).addClass("tab-hover")
            }).on("mouseleave", "button.lobby-tab", function() {
                c(this).removeClass("tab-hover")
            });
            c(b).resize(function() {
                v.resizeLobby()
            });
            v.resizeLobby();
            v._buildLogin();
            v._buildReg();
            f.find("#ring-tab").trigger("click");
            f.find("#soft-tab").trigger("click");
            //f.find("#play-tab").trigger("click");
            //$.when(v._ring_snap()).done(f.find("#play-tab").trigger("click"));
        },
        _filter_money: function(f) {
            var e = this,
                i = e.options,
                g = e.element;
            var h = g.find(".tab-info.games.select tbody tr:visible");
            if (f == "real") {
                h.filter("[did!=1]").show();
                h.filter("[did=1]").hide()
            } else {
                if (f == "play") {
                    h.filter("[did=1]").show();
                    h.filter("[did!=1]").hide()
                }
            }
        },
        watch_table_res: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            c("#table-ring").append(c("<div />").attr("id", "tring" + f.table_id).table_ring(f))
        },
        watch_tour_res: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            c.extend(f, {
                tourData: h.tourData[f.tour_id],
                tourClasses: h.tourClasses,
                gameState: h.gameState,
                gameTabs: h.gameTabs,
                epochDiff: h.epochDiff
            });
            c("#tour-lobby").append(c("<div />").attr("id", "tour" + f.tour_id).tour(f))
        },
        _destroy: function() {},
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
            c.each(e.ringData[i].plr_map, function(o, g) {
                s = ++o;
                n += "<tr><td>" + s + "</td><td>" + e.loginData[g.login_id].username + "</td><td>" + g.chips + "</td></tr>"
            });
            h.html(n);
            m.show()
        },
        destroy: function() {},
        _buildReg: function() {
            var g = this,
                n = g.options,
                j = g.element,
                e = c("<input />").attr({
                    id: "signup-name",
                    name: "username",
                    placeholder: "Username",
                    type: "text",
                    maxlength: 12,
                    pattern: "[A-Za-z]([0-9a-zA-Z_]){3,12}"
                }).prop({
                    autofocus: true,
                    required: true
                }),
                h = c("<input />").attr({
                    id: "signup-email",
                    placeholder: "Email (optional)",
                    maxlength: 30,
                    name: "email",
                    type: "email"
                }).prop({
                    required: true
                }),
                i = c("<input />").attr({
                    id: "signup-pass",
                    placeholder: "Password",
                    maxlength: 12,
                    name: "password",
                    type: "password"
                }).prop({
                    required: true
                }),
                m = c("<input />").attr({
                    id: "confirm-pass",
                    placeholder: "Confirm Password",
                    maxlength: 12,
                    name: "password",
                    type: "password"
                }).prop({
                    required: true
                });
            var l = j.find("#new-account");
            l.append(c("<div />").addClass("modal-header").html("Create New Account"), c("<form />").attr("id", "signup-form").append(c("<div />").attr("id", "signup-un").html("Username:"), e, c("<div />").attr("id", "signup-pw").html("Password:"), i, c("<div />").attr("id", "signup-cp").html("Password:"), m, c("<div />").attr("id", "signup-em").html("Email:"), h).submit(function(f) {
                f.preventDefault();
                l.hide();
                if (i.val() !== m.val()) {
                    g.modal_message("Passwords don't match")
                } else {
                    var o = {
                        username: e.val(),
                        password: i.val()
                    };
                    if (h.val()) {
                        o.email = h.val()
                    }
                    c("#poker-main").main("register", o)
                }
            }), c("<button />").addClass("modal-ok").html("OK").click(function() {
                c("#signup-form").submit()
            }), c("<button />").addClass("modal-cancel").html("Cancel").click(function() {
                l.hide()
            }))
        },
        register_res: function(g) {
            var f = this;
            var e;
            if (g.success) {
                e = "Registered! Welcome " + g.username + "!";
                f.login_success(g)
            } else {
                e = g.message
            }
            this.modal_message(e)
        },
        _buildLogin: function() {
            var g = this,
                l = g.options,
                i = g.element,
                j = i.find("#login-box"),
                e = c("<input />").attr({
                    id: "login-name",
                    name: "username",
                    placeholder: "Username",
                    type: "text",
                    maxlength: 12,
                    pattern: "[A-Za-z]([0-9a-zA-Z_]){3,12}"
                }).prop({
                    autofocus: true,
                    required: true
                }),
                h = c("<input />").attr({
                    id: "login-pass",
                    placeholder: "Password",
                    maxlength: 12,
                    name: "password",
                    type: "password"
                }).prop({
                    required: true
                });
            j.append(c("<div />").addClass("modal-header").html("Log-In"), c("<form />").attr("id", "login-form").append(c("<div />").attr("id", "label-name").html("Username:"), e, c("<div />").attr("id", "label-pass").html("Password:"), h).submit(function(f) {
                f.preventDefault();
                c("#poker-main").main("login", {
                    username: e.val(),
                    password: h.val()
                });
                j.hide()
            }), c("<button />").attr({
                id: "login-create"
            }).html("Create New Account").click(function() {
                j.hide();
                c("#new-account").show();
                c("#signup-name").focus()
            }), c("<button />").addClass("modal-ok").html("OK").click(function() {
                c("#login-form").submit()
            }), c("<button />").addClass("modal-cancel").html("Cancel").click(function() {
                j.hide()
            }))
        },
        _updateClock: function() {
            var e = this,
                i = e.options,
                f = e.element;
            var h = (new Date).toTimeString().split(/\s/);
            var l = h[2].replace(/\W/g, "");
            var g = h[0].split(":");
            var j = g[0] + ":" + g[1] + " " + l;
            f.find("#lobby-clock").html(j)
        },
        _updateNews: function() {
            var e = this,
                g = e.options,
                f = e.element;
            if (!g.news.length) {
                return
            }
            var h = g.news.shift();
            g.news.push(h);
            f.find("#news-body").slideUp("slow", function() {
                c(this).html(h).slideDown("slow")
            })
        },
        _buildTable: function(h) {
            var e = this,
                i = e.options,
                g = e.element;
            var f = "";
            c.each(h, function(m, j) {
                var o = i.colData[j][0];
                var l = i.colData[j][1];
                f += '<th data-sort-dir="asc" data-sort="' + l + '">' + o + "</th>"
            });
            return c("<div/>").addClass("table-box").append(c("<table />").append(c("<thead />").append(c("<tr>").html(f)), c("<tbody />")).stupidtable().bind("aftertablesort", function(l, n) {
                $this = c(this);
                $this.find("tbody tr:visible:first").trigger("click");
                var j = $this.find("th");
                j.find(".arro").remove();
                var m = n.direction === "asc" ? "↑" : "↓";
                j.eq(n.column).append('<span class="arro">' + m + "</span>")
            }))
        },
        resizeLobby: function(g) {
            var h = this.options,
                f = b.innerWidth,
                e = f * h.heightToWidth;
            this.element.css({
                height: (e) + "px",
                fontSize: (f / 800) + "em"
            })
        },
        guest_login: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            h.epochDiff = (new Date).getTime() - (f.epoch * 1000);
            h.news = f.news;
            h.myData = {
                login_id: f.login_id,
                username: f.username,
                chips: f.chips
            };
            e._updateClock();
            clearInterval(h.clockTimer);
            setTimeout(function() {
                e._updateClock();
                h.clockTimer = setInterval(function() {
                    e._updateClock()
                }, 60000)
            }, (62 - (new Date).getSeconds()));
            if (h.news.length) {
                g.append(c("<div />").attr("id", "lobby-news").append(c("<div />").attr("id", "news-head").html("News"), c("<div />").attr("id", "news-body")));
                e._updateNews();
                setInterval(function() {
                    e._updateNews()
                }, 15000)
            }
            g.find("#welcome").empty().append(c("<div/>").attr("id", "username").html(h.myData.username), c("<div/>").attr("id", "logout").html("&nbsp[ Logout ]").click(function() {
                c("#poker-main").main("logout")
            }));
            g.find("#strat-tab").trigger("click")
        },
        modal_message: function(i) {
            var h = this,
                f = this.element.find("#modal-box"),
                j = c("<div />").addClass("modal-mes").html(i),
                e = c("<button />").addClass("modal-ok center").html("OK"),
                g = f.width();
            f.append(j, e.click(function() {
                f.hide()
            })).show();
            setTimeout(function() {
                f.fadeOut(1200, function() {
                    c(this).children().remove()
                })
            }, 2000)
        },
        _buildCashier: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            g.append(c("<div />").attr("id", "cashier").addClass("big-modal").append(c("<div />").attr("id", "cash-head").html("CASHIER"), c("<div />").attr("id", "cash-close").click(function() {
                c("#cashier").hide()
            }), c("<div />").attr("id", "cash-one").append(c("<div />").attr("id", "pers-head").addClass("head").html("Personal Information"), c("<div />").attr("id", "cash-user").addClass("cash-block").append(c("<div />").addClass("cash-cat").html("Username:"), c("<div />").addClass("cash-det")), c("<div />").attr("id", "cash-email").addClass("cash-block").append(c("<div />").addClass("cash-cat").html("Email:"), c("<div />").addClass("cash-det")), c("<div />").attr("id", "cash-deposit").addClass("cash-block").append(c("<div />").addClass("cash-cat").html("Rating:"), c("<div />").addClass("cash-det").html("0"))), c("<div />").attr("id", "cash-two").append(c("<div />").attr("id", "acct-head").addClass("head").html("Account Balance"), c("<div />").attr("id", "play-head").addClass("head").html("PLAY MONEY"), c("<div />").attr("id", "play-avail").addClass("cash-block").append(c("<div />").addClass("cash-cat").html("Available:"), c("<div />").addClass("cash-det")), c("<div />").attr("id", "play-inplay").addClass("cash-block").append(c("<div />").addClass("cash-cat").html("In Play:"), c("<div />").addClass("cash-det")), c("<div />").attr("id", "play-total").append(c("<div />").addClass("cash-cat").html("Total:"), c("<div />").addClass("cash-det"))), c("<div />").attr("id", "cash-three").append(c("<button />").attr("id", "cash-reload").html("Reload Chips").click(function() {
                c("#poker-main").main("reload")
            }), c("<button />").attr("id", "cash-leave").html("Leave Cashier").click(function() {
                c("#cashier").hide()
            }))))
        },
        _updateCashier: function() {
            var f = this,
                i = f.options,
                h = f.element;
            var g;
            var e = {
                username: function(j) {
                    c("#cash-user .cash-det").html(j)
                },
                email: function(j) {
                    c("#cash-email .cash-det").html(j)
                },
                chips: function(j) {
                    c("#real-avail .cash-det").html(0);
                    c("#play-avail .cash-det").html(j[1])
                },
                ring_play: function(l) {
                    var m = 0;
                    var j = 0;
                    c.each(l, function(o, n) {
                        if (i.ringData[o].director_id == 1) {
                            m += n
                        } else {
                            j += n
                        }
                    });
                    g = m + i.myData.chips[1];
                    c("#real-inplay .cash-det").html(j);
                    c("#real-total .cash-det").html(j);
                    c("#play-inplay .cash-det").html(m);
                    c("#play-total .cash-det").html(g)
                }
            };
            c.each(i.myData, function(j, l) {
                if (j in e) {
                    e[j](l)
                }
            });
            c("#cash-deposit .cash-det").html(g + "/" + i.myData.invested[1] + " = " + Math.round(g / i.myData.invested[1] * 1000) / 1000)
        },
        login_success: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            h.myData = f;
            e._buildCashier();
            g.find("#lobby-red").html("Cashier").off("click").click(function() {
                c("#poker-main").main("login_info")
            });
            g.find("#username").html(h.myData.username)
        },
        login_res: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            if (f.success) {
                e.modal_message("Success! Welcome " + f.username + "!");
                e.login_success(f)
            } else {
                e.modal_message(f.message)
            }
        },
        login_update: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            h.myData = f
        },
        login_info_res: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            if (f.success) {
                h.myData = f;
                e._updateCashier();
                c("#cashier").show()
            } else {
                e.modal_message(f.message)
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
            if (l.loginData[g.from] && l.loginData[g.from]["block"]) {
                return
            }
            var m = l.loginData[g.from];
            var i = m ? m.username : "Guest" + g.from;
            var j = m ? m.color : "black";
            var e = h.find("#" + g.channel + "-chat");
            e.append(c("<div />").addClass("chat-msg").append(c("<a />").addClass("chat-handle").html(i).css("color", j), c("<span />").html(": " + g.message)));
            e.animate({
                scrollTop: e[0].scrollHeight
            })
        },
        notify_login: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            this.notify_logout(f);
            f.color = "rgb(" + Math.floor(Math.random() * 256) + "," + Math.floor(Math.random() * 256) + "," + Math.floor(Math.random() * 256) + ")";
            h.loginData[f.login_id] = f;
            g.find("#social-info .table-box tbody").append(c("<tr />").attr("login_id", f.login_id).append(c("<td />").html(f.username), c("<td />").addClass("block yes").click(function() {
                var i = c(this);
                i.toggleClass("yes");
                if (i.hasClass("yes")) {
                    h.loginData[f.login_id]["block"] = true;
                    i.html("Yes")
                } else {
                    h.loginData[f.login_id]["block"] = false;
                    i.html("No")
                }
            }).click()))
        },
        notify_logout: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            delete h.loginData[f.login_id];
            g.find("#social-info .table-box tbody tr[login_id=" + f.login_id + "]").remove()
        },
        notify_create_tour: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            e.notify_destroy_tour(f);
            e._add_tour(f)
        },
        notify_destroy_tour: function(e) {
            delete this.options.tourData[e.tour_id];
            this.element.find("#ltour" + e.tour_id).remove()
        },
        tour_snap: function(f) {
            var e = this,
                i = e.options,
                h = e.element;
            var g = h.find("#tour-info tbody");
            g.empty();
            c.each(f, function(j, l) {
                e._add_tour(l)
            })
        },
        _add_tour: function(l) {
            var p = this,
                f = p.options,
                h = p.element;
            var i = h.find("#tour-info tbody");
            var g = (new Date(l.start_time * 1000 + f.epochDiff)).toString().split(/\s/);
            var n = g[4].split(":");
            l.start = g[1] + " " + g[2] + " " + n[0] + ":" + n[1];
            var j = l.game_class == "dealers" ? "--" : l.limit;
            l.desc = l.desc ? l.desc : j + " " + f.gameTabs[l.game_class][0];
            var e = (new Date(l.end_time * 1000 + f.epochDiff)).toString().split(/\s/);
            var m = e[4].split(":");
            l.end = e[1] + " " + e[2] + " " + m[0] + ":" + m[1];
            l.class_name = f.tourClasses[l.tour_class];
            f.tourData[l.tour_id] = l;
            c("<tr />").attr({
                id: "ltour" + l.tour_id,
                tour_id: l.tour_id,
                did: l.director_id,
                game_class: l.game_class
            }).append(c("<td />").html(l.tour_id), c("<td />").html(l.start), c("<td />").html(l.desc), c("<td />").html(l.buy_in + l.entry_fee), c("<td />").addClass("ltour-state"), c("<td />").addClass("ltour-enrolled")).appendTo(i);
            p._update_tour_tab(l)
        },
        _update_tour_tab: function(j) {
            var f = this,
                i = f.options,
                h = f.element;
            var g = h.find("#ltour" + j.tour_id);
            var e = {
                state: function(l) {
                    g.find(".ltour-state").html(i.gameState[j.state])
                },
                enrolled: function(l) {
                    g.find(".ltour-enrolled").html(l)
                }
            };
            c.each(j, function(l, m) {
                if (l in e) {
                    e[l](m)
                }
            })
        },
        ring_snap: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            c.each(f, function(j, l) {
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
            c.each(h.ringData, function(l, j) {
                var m = j.small_blind + "/" + j.big_blind;
                var i = j.game_class == "dealers" ? "--" : j.limit;
                c("<tr />").attr({
                    id: "lring" + l,
                    table_id: j.table_id,
                    did: j.director_id,
                    game_class: j.game_class
                }).addClass("lring").append(c("<td />").addClass("table-id").html(j.table_id), c("<td />").html(h.gameTabs[j.game_class][0]), c("<td />").addClass().html(m), c("<td />").addClass().html(i), c("<td />").addClass().html(j.chair_count), c("<td />").addClass("plr-count"), c("<td />").addClass("avg-pot"), c("<td />").addClass("plrs-flop"), c("<td />").addClass("hhr")).appendTo(f);
                e._update_ring_tab(j);
            }, g.find("#play-tab").trigger("click") );
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
        notify_lt_update: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            c.extend(h.tourData[f.tour_id], f);
            e._update_tour_tab(f)
        },
        notify_lr_update: function(f) {
            var e = this,
                h = e.options,
                g = e.element;
            c.extend(h.ringData[f.table_id], f);
            e._update_ring_tab(f)
        },
        _update_ring_tab: function(g) {
            var f = this,
                j = f.options,
                i = f.element;
            var h = i.find("#lring" + g.table_id);
            if (i.find("#ring-box").attr("tid") == g.table_id) {
                h.trigger("click")
            }
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
            c.each(g, function(l, m) {
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
