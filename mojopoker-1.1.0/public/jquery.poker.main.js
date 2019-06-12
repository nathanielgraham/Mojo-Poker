;(function($, window, document, undefined) {
    $.widget('poker.main', {

        _create: function() {
            var self = this,
                o = self.options,
                el = self.element;

            //      el.attr("id", "poker-main");

            $.each(o, function(key, value) {
                self._setOption(key, value);
            });

            if (!("WebSocket" in window)) {
                var m = $("#modal-box");
                m.append(
                    $("<div />").addClass("modal-mes")
                    .html("Your browser needs to be updated. Please download Mozilla Firefox."),
                    $("<button />").addClass("modal-ok center").html("OK").click(function() {
                        m.hide();
                    })
                ).show()
            }

            var ws = new WebSocket(o.ws);

            ws.onerror = function(e) {
                self._recModal('Connection closed.');
            }
            ws.onclose = function(e) {
                self._recModal('Connection closed.');
            }
            ws.onopen = function(e) {
                ws.send(JSON.stringify(['guest_login']));
            }
            ws.onmessage = function(e) {
                var msg = JSON.parse(e.data);
                self._msgHandler(msg[0], msg[1]);
            }

            var lo = $("#lobby-main");
            lo.lobby();

            self._setOptions({
                wsock: ws,
                lobbyMain: lo
            });

            /*
                  el.append(
                    $("<div />").attr("id", "table-ring"),
                    $("<div />").attr("id", "table-tour"),
                    $("<div />").attr("id", "table-fast"),
                    $("<div />").attr("id", "tour-lobby"),
                    lo
                  );
            */
            self._img_preload();
            //self._msgHandler('watch_tour_res', { tour_id: 1 });
        },

        _img_preload: function() {
            $.each(['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'], function(i1, r) {
                $.each(['c', 'd', 'h', 's'], function(i2, s) {
                    (new Image()).src = 'img/deck/' + r + s + '.png';
                })
            })

            function preload(imgs) {
                $(imgs).each(function() {
                    (new Image()).src = this;
                });
            }
            preload([
                'img/deck/Joker.png',
                'img/deck/cb.png',
                'img/wall.png',
                'img/table.png',
                'img/title_left.png',
                'img/title_left_active.png',
                'img/title_right.png',
                'img/title_right_active.png',
                'img/button.png',
                'img/stand.png',
                'img/chip-1.png',
                'img/chip-5.png',
                'img/chip-25.png',
                'img/chip-50.png',
                'img/chip-100.png',
                'img/chip-500.png',
                'img/chip-1000.png',
                'img/chip-2500.png',
                'img/chip-10000.png',
                'img/chip-50000.png',
                'img/chip-500000.png',
                'img/chip-100000.png',
                'img/chip-2500000.png'
            ]);
        },

        destroy: function() {
            this.element.remove();
            this._super('_destroy');
        },

        _recModal: function(t) {

            var self = this,
                m = $("#modal-box");
            m.empty();

            m.append(
                $("<div />").addClass("modal-mes").html(t),
                $("<button />").addClass("modal-ok center").html("Reconnect")
                .click(function() {
                    //m.empty();
                    //m.hide();
                    self.element.empty();
                    self._create();
                }),
                $("<button />").addClass("modal-cancel center").html("Cancel")
                .click(function() {
                    self.destroy();
                })
            ).show();
        },
        watch_tour: function(v) {
            this.options.wsock.send(JSON.stringify(['watch_tour', v]));
        },
        unwatch_tour: function(v) {
            this.options.wsock.send(JSON.stringify(['unwatch_tour', v]));
        },
        table_chips: function(v) {
            this.options.wsock.send(JSON.stringify(['table_chips', v]));
        },
        logout: function() {
            this.options.wsock.send(JSON.stringify(['logout']));
        },
        login_info: function() {
            this.options.wsock.send(JSON.stringify(['login_info']));
        },
        table_opts: function(v) {
            this.options.wsock.send(JSON.stringify(['table_opts', v]));
            //alert('table_opts ' + JSON.stringify(v));
        },
        pick_game: function(v) {
            this.options.wsock.send(JSON.stringify(['pick_game', v]));
        },
        table_chat: function(v) {
            this.options.wsock.send(JSON.stringify(['table_chat', v]));
        },
        join_channel: function(v) {
            this.options.wsock.send(JSON.stringify(['join_channel', v]));
        },
        unjoin_channel: function(v) {
            this.options.wsock.send(JSON.stringify(['unjoin_channel', v]));
        },
        write_channel: function(v) {
            this.options.wsock.send(JSON.stringify(['write_channel', v]));
        },
        watch_table: function(v) {
            this.options.wsock.send(JSON.stringify(['watch_table', v]));
        },
        unwatch_table: function(v) {
            this.options.wsock.send(JSON.stringify(['unwatch_table', v]));
        },
        authorize: function(v) {
            var jso = JSON.stringify(['authorize', v]);
            //alert('authorize: ' + jso); 
            this.options.wsock.send(jso);
        },
        join_ring: function(v) {
            var jso = JSON.stringify(['join_ring', v]);
            //alert('join_ring: ' + jso); 
            this.options.wsock.send(jso);
        },
        unjoin_ring: function(v) {
            var jso = JSON.stringify(['unjoin_ring', v]);
            this.options.wsock.send(jso);
        },
        login: function(v) {
            var j = JSON.stringify(['login', v]);
            this.options.wsock.send(j);
        },
        register: function(v) {
            var j = JSON.stringify(['register', v]);
            this.options.wsock.send(j);
        },
        bet: function(v) {
            var j = JSON.stringify(['bet', v]);
            this.options.wsock.send(j);
        },
        check: function(v) {
            var j = JSON.stringify(['check', v]);
            this.options.wsock.send(j);
        },
        fold: function(v) {
            var j = JSON.stringify(['fold', v]);
            this.options.wsock.send(j);
        },
        discard: function(v) {
            var j = JSON.stringify(['discard', v]);
            this.options.wsock.send(j);
        },
        draw: function(v) {
            var j = JSON.stringify(['draw', v]);
            this.options.wsock.send(j);
        },
        reload: function(v) {
            var j = JSON.stringify(['reload']);
            this.options.wsock.send(j);
        },

        _msgHandler: function(k, v) {
            var self = this,
                o = self.options,
                el = self.element;

            var fnMap = {
                'join_channel_res': function(v) {
                    o.lobbyMain.lobby('join_channel_res', v);
                },
                'authorize_res': function(v) {
                    o.lobbyMain.lobby('authorize_res', v);
                },
                'unjoin_channel_res': function(v) {
                    o.lobbyMain.lobby('unjoin_channel_res', v);
                },
                'notify_logins': function(v) {
                    $("#lobby-count > span").html(v.login_count);
                },
                'notify_leaders': function(v) {
                    o.lobbyMain.lobby('notify_leaders', v);
                },
                'table_snap': function(v) {
                    el.find("#tring" + v.table_id).table_ring("table_snap", v);
                },
                'table_update': function(v) {
                    el.find("#tring" + v.table_id).table_ring("table_update", v);
                },
                'guest_login': function(v) {
                    o.login_id = v.login_id;
                    o.lobbyMain.lobby('guest_login', v);
                },
                'login_snap': function(v) {
                    $.each(v, function(i, value) {
                        self._msgHandler('notify_login', value);
                    });
                },
                'ring_snap': function(v) {
                    o.lobbyMain.lobby('ring_snap', v);
                },
                'tour_snap': function(v) {
                    o.lobbyMain.lobby('tour_snap', v);
                },
                'message_snap': function(v) {
                    $.each(v, function(i, value) {
                        self._msgHandler('notify_message', value);
                    });
                },
                'notify_message': function(v) {
                    if (v.tour_id) {

                    } else if (v.table_id) {
                        el.find("#tring" + v.table_id).table_ring('notify_message', v);
                    } else {
                        o.lobbyMain.lobby('notify_message', v);
                    }
                },
                'player_update': function(v) {
                    el.find("#tring" + v.table_id).table_ring('player_update', v);
                },
                'player_snap': function(v) {
                    if (v.length) {
                        var table_id = v[0].table_id;
                        var r = el.find("#tring" + table_id);
                        $.each(v, function(i, value) {
                            r.table_ring('notify_join_table', value);
                        });
                        r.table_ring('player_snap', v);
                    }
                },
                'move_button': function(v) {
                    el.find("#tring" + v.table_id).table_ring('move_button', v);
                },
                'new_game': function(v) {
                    el.find("#tring" + v.table_id).table_ring('new_game', v);
                },
                'end_game': function(v) {
                    el.find("#tring" + v.table_id).table_ring('end_game', v);
                },
                'notify_post': function(v) {
                    el.find("#tring" + v.table_id).table_ring('notify_post', v);
                },
                'deal_hole': function(v) {
                    el.find("#tring" + v.table_id).table_ring('deal_hole', v);
                },
                'begin_new_round': function(v) {
                    el.find("#tring" + v.table_id).table_ring('begin_new_round', v);
                },
                'begin_new_action': function(v) {
                    el.find("#tring" + v.table_id).table_ring('begin_new_action', v);
                },
                'your_turn': function(v) {
                    el.find("#tring" + v.table_id).table_ring('your_turn', v);
                },
                'deal_community': function(v) {
                    el.find("#tring" + v.table_id).table_ring('deal_community', v);
                },
                'showdown': function(v) {
                    el.find("#tring" + v.table_id).table_ring('showdown', v);
                },
                'high_winner': function(v) {
                    el.find("#tring" + v.table_id).table_ring('high_winner', v);
                },
                'low_winner': function(v) {
                    el.find("#tring" + v.table_id).table_ring('low_winner', v);
                },
                'notify_login': function(v) {
                    o.lobbyMain.lobby('notify_login', v);
                },
                //'notify_lobby_update': function(v) {
                'notify_lr_update': function(v) {
                    o.lobbyMain.lobby('notify_lr_update', v);
                },
                'notify_lt_update': function(v) {
                    o.lobbyMain.lobby('notify_lt_update', v);
                },
                'login_update': function(v) {
                    o.lobbyMain.lobby('login_update', v);
                },
                'notify_logout': function(v) {
                    o.lobbyMain.lobby('notify_logout', v);
                },
                'notify_create_ring': function(v) {
                    o.lobbyMain.lobby('notify_create_ring', v);
                },
                'notify_destroy_ring': function(v) {
                    //el.find('#lobby-main').lobby('notify_destroy_ring', v) ;
                    o.lobbyMain.lobby('notify_destroy_ring', v);
                },
                'tour_update': function(v) {
                    //$("<div />").attr('id', 'tour' + v.tour_id).tour(v)
                    el.find("#tour" + v.tour_id).tour('tour_update', v);
                },
                'notify_create_tour': function(v) {
                    o.lobbyMain.lobby('notify_create_tour', v);
                },
                'notify_destroy_tour': function(v) {
                    //el.find('#lobby-main').lobby('notify_destroy_ring', v) ;
                    o.lobbyMain.lobby('notify_destroy_tour', v);
                },
                /*
                        'lobby_join_table': function(v) {
                          o.lobbyMain.lobby('lobby_join_table', v) ;
                        },
                */
                'notify_join_hydra': function(v) {
                    if (v.tour_id) {

                    } else if (v.table_id) {
                        el.find("#tring" + v.table_id).table_ring('notify_join_hydra', v);
                    }
                },
                'notify_join_table': function(v) {
                    v.color = o.lobbyMain.lobby('option', 'loginData.' + v.login_id + '.color');
                    if (v.tour_id) {

                    } else if (v.table_id) {
                        el.find("#tring" + v.table_id).table_ring('notify_join_table', v);
                    }
                },
                /*
                        'lobby_unjoin_table': function(v) {
                          o.lobbyMain.lobby('lobby_unjoin_table', v) ;
                        },
                */
                'notify_unjoin_table': function(v) {
                    if (v.tour_id) {

                    } else if (v.table_id) {
                        el.find("#tring" + v.table_id).table_ring('player_unjoin', v);
                    }
                },
                'notify_pick_game': function(v) {
                    el.find("#tring" + v.table_id).table_ring('notify_pick_game', v);
                },
                'notify_fold': function(v) {
                    el.find("#tring" + v.table_id).table_ring('notify_fold', v);
                },
                'notify_bet': function(v) {
                    el.find("#tring" + v.table_id).table_ring('notify_bet', v);
                },
                'notify_check': function(v) {
                    el.find("#tring" + v.table_id).table_ring('notify_check', v);
                },
                'notify_discard': function(v) {
                    el.find("#tring" + v.table_id).table_ring('notify_discard', v);
                },
                'notify_draw': function(v) {
                    el.find("#tring" + v.table_id).table_ring('notify_draw', v);
                },
                'notify_user_chips': function(v) {},

                // RING SPECIFIC
                'table_chips_res': function(v) {
                    el.find("#tring" + v.table_id).table_ring('table_chips_res', v);
                },
                //'notify_table_chips': function(v) {
                //  el.find("#tring" + v.table_id).table_ring('notify_table_chips', v);
                //},
                'join_ring_res': function(v) {
                    //alert('join_ring_res: ' + JSON.stringify(v));
                    el.find("#tring" + v.table_id).table_ring('join_ring_res', v);
                },
                'unjoin_ring_res': function(v) {
                    el.find("#tring" + v.table_id).table_ring('unjoin_ring_res', v);
                },
                //'unwatch_ring_res': function(v) {
                'unwatch_table_res': function(v) {
                    if (v.tour_id) {

                    } else if (v.table_id) {
                        el.find("#tring" + v.table_id).remove();
                    }

                    //alert('unwatch_ring_res: ' + JSON.stringify(v) );
                    //el.find("#tring" + v.table_id).remove();
                },
                //'watch_ring_res': function(v) {
                'watch_table_res': function(v) {
                    //alert('watch_ring_res: ' + JSON.stringify(v) );
                    //self._msgHandler('unwatch_ring_res', v);
                    // var ring = $("<div />)").attr('id', 'tring' + v.table_id);

                    if (v.tour_id && v.success) {

                    } else if (v.table_id && v.success) {
                        self._msgHandler('unwatch_table_res', v);
                        //o.lobbyMain.lobbyfind("#table-ring").append(
                        o.lobbyMain.lobby('watch_table_res', v);
                        //el.find(".stacked").draggable("option", "stack", ".stacked");
                        //el.find("#table-ring").append(
                        //  $("<div />").attr('id', 'tring' + v.table_id).table_ring(v)
                        //);
                    }
                },
                'watch_tour_res': function(v) {
                    self._msgHandler('unwatch_tour_res', v);
                    o.lobbyMain.lobby('watch_tour_res', v);

                    /*
                              v.epochDiff = o.lobbyMain.lobby('option', 'epochDiff');
                              $("#tour-lobby").append(
                                $("<div />").attr('id', 'tour' + v.tour_id).tour(v)
                              );
                    */
                },
                'unwatch_tour_res': function(v) {
                    el.find("#tour" + v.tour_id).remove();
                },
                'login_res': function(v) {
                    o.login_id = v.login_id;
                    o.lobbyMain.lobby('login_res', v);
                },
                'login_info_res': function(v) {
                    o.lobbyMain.lobby('login_info_res', v);
                },
                'register_res': function(v) {
                    o.lobbyMain.lobby('register_res', v);
                },
                'table_opts_res': function(v) {
                    el.find("#tring" + v.table_id).table_ring('table_opts_res', v);
                },
                'pick_game_res': function(v) {
                    el.find("#tring" + v.table_id).table_ring('pick_game_res', v);
                },
                'bet_res': function(v) {
                    el.find("#tring" + v.table_id).table_ring('bet_res', v);
                },
                'check_res': function(v) {
                    el.find("#tring" + v.table_id).table_ring('check_res', v);
                },
                'fold_res': function(v) {
                    el.find("#tring" + v.table_id).table_ring('fold_res', v);
                },
                'discard_res': function(v) {
                    el.find("#tring" + v.table_id).table_ring('discard_res', v);
                },
                'draw_res': function(v) {
                    el.find("#tring" + v.table_id).table_ring('draw_res', v);
                },
                'default': function(v) {}
            };
            if (k in fnMap) {
                fnMap[k](v);
            }
        },
        _setOption: function(key, value) {
            var self = this,
                o = self.options,
                el = self.element;

            var fnMap = {
                'ws': function() {
                    //o.webSocket = value;
                },
                'wsock': function() {
                    //o.wsock = value;
                },
                'lobbyMain': function() {
                    //o.lobbyMain = value;
                }
            };

            if (key in fnMap) {
                o[key] = value;
                fnMap[key]();
            }
        }
    });
})(jQuery, window, document);
