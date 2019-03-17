;(function ( $, window, document, undefined ) {

  $.widget('poker.table', {
 
    options: {
      heightToWidth: 3 / 4,
      windowRatio: 1 / 2,
      windowMin: 1 / 3,
      windowMax: 15 / 20,
      dfd: new jQuery.Deferred(),
      shoe_css: { left: '26%', top: '5%' },
      pot_css: { left: '45%', top: '24%' },
      chipSizes: [1000000, 250000, 50000, 10000,2500,500,100,25,5,1],
      gameChoices: { 
        1: "NL Hold'em",
        2: "FL Hold'em (Jokers Wild)",
        3: "PL Omaha",
        4: "PL Omaha Hi-Lo",
        5: "NL Badugi",
        6: "NL Crazy Pineapple",
        7: "PL 5 Card Omaha",
        8: "PL 5 Card Omaha Hi-Lo",
        9: "PL Courcheval",
        10: "PL Courcheval Hi-Lo",
        11: "NL 5 Card Draw",
        12: "NL 2-7 Single Draw",
        13: "NL 2-7 Triple Draw",
        14: "NL Badacey",
        15: "NL Badeucy",
        16: "NL A-5 Single Draw",
        17: "NL A-5 Triple Draw",
        18: "NL Pineapple",
        19: "NL 5 Card Draw (Jokers Wild)",
        20: "NL 5 Card Draw (Deuces Wild)",
        21: "FL 7 Card Stud",
        22: "FL 7 Card Stud Hi-Lo",
        23: "FL Razz",
        24: "FL High Chicago",
        25: "FL 7 Card Stud (Jokers Wild)",
        26: "FL Follow the Queen",
        27: "FL The Bitch",
      },
      gameClass: { 
        dealers: "Dealer's Choice",
        holdem: "Hold'em",
        holdemjokers: "Hold'em (Jokers Wild)",
        omaha: "Omaha",
        omahahilo: "Omaha Hi-Lo",
        badugi: "Badugi",
        crazypine: "Crazy Pineapple",
        omahafive: "5 Card Omaha",
        omahafivehilo: "5 Card Omaha Hi-Lo",
        courcheval: "Courcheval",
        courchevalhilo: "Courcheval Hi-Lo",
        fivedraw: "5 Card Draw",
        singledraw27: "2-7 Single Draw",
        tripledraw27: "2-7 Triple Draw",
        badacey: "Badacey",
        badeucy: "Badeucy",
        singledrawa5: "A-5 Single Draw",
        tripledrawa5: "A-5 Triple Draw",
        pineapple: "Pineapple",
        drawjokers: "5 Card Draw (Jokers Wild)",
        drawdeuces: "5 Card Draw (Deuces Wild)",
        sevenstud: "7 Card Stud",
        sevenstudhilo: "7 Card Stud Hi-Lo",
        razz: "Razz",
        highchicago: "High Chicago",
        sevenstudjokers: "7 Card Stud (Jokers Wild)",
        ftq: "Follow the Queen",
        bitch: "The Bitch",
      },
      login_info: {
        d: { handle: 'Dealer', color: 'black' },
        k: { handle: 'Kibitz', color: 'blue' } 
      },
      chair_info: { 
      },
      chair_count: 0
    },
    _create: function() {
             
      var self = this,
             o = self.options,
            el = self.element;

      o.cardSnd = new Audio("snd/cardPlace3.ogg");
      o.betSnd = new Audio("snd/betSnd.ogg");
      o.pokerMain = $("#poker-main");
      o.chatBox = $("<div />").addClass("chat-box");

      var ci = $("<input />").addClass("chat-input").attr({type: 'text', maxlength: 30});
      var fo = $("<form />").addClass("chat-form").append(ci).submit(function(event) {
        event.preventDefault();
        var rx = /^[\w\s\.\,\?!@#\$%^&\*\(\)_]{0,30}$/;
        if(rx.test(ci.val())) {
          o.pokerMain.main("table_chat", { table_id: o.table_id, message: ci.val() });
        }
        ci.val('');
      });
      var stakes = o.small_blind + "/" + o.big_blind;
      var game_info = '';
      if (o.game_class !== 'dealers') {
        game_info += o.limit + ' ';
      }
      game_info += o.gameClass[o.game_class];
      el.addClass("ui-widget ui-front stacked table " + o.game_class).attr({ 'chair-count': o.chair_count, 'game-choice': o.game_class }).append(  
        $("<div />").addClass("table-wall"),
        $("<div />").addClass("header-main"),
        $("<div />").addClass("header-info")
        .html("Table#" + o.table_id + " " + stakes + " " + game_info + " ")
        .append(
          $("<div />").addClass("choice-info")
        ), 
        $("<div />").addClass("choice-info"), 
        $("<div/>").addClass("header-icon header-icon-resize header-icon-max").click( function() { 
          self._resizeMax($(this));
        }),
        $("<div/>").addClass("header-icon header-icon-close").click( function() { 
          o.pokerMain.main("unwatch_table", { table_id: o.table_id });
        }),
        $("<div />").addClass("board"),
        $("<div />").addClass("community"),
        $("<div />").addClass("pot"),
        //$("<div />").addClass("stack pot-stack"),
        $("<div />").addClass("panel-box").append(
          $("<div />").addClass("chat-button"),
          $("<div />").addClass("notes-button"),
          $("<div />").addClass("stats-button"),
          $("<div />").addClass("info-button")
        ),
        fo,
        o.chatBox,
        //$("<div />").addClass("chat-box"),
        $("<div />").addClass("notes-box"),
        $("<div />").addClass("stats-box"),
        $("<div />").addClass("info-box"),
        $("<div />").addClass("slider-box").append(
          $("<div />").addClass("bet-slider"),
          $("<input />").addClass("bet-amount").attr({type: 'text'})
        ),
        $("<div />").addClass("action-box").append(
          $("<div />").addClass("action").attr({no: 0}),
          $("<div />").addClass("action").attr({no: 1}),
          $("<div />").addClass("action").attr({no: 2})
        ),
        $("<div />").addClass("table-msg table-mod")
      );
      
      self.buildSelector();

      // create chairs
      for(var i = 0; i < o.chair_count; i++) {
        el.append(
          $("<div />").addClass("seat seat" + i).attr('pos', i)
        );
        self.player_unjoin({ chair: i, table_id: o.table_id });
      }

      el.resizable({
        aspectRatio: true,
        resize: function(event, ui) {
          $(this).css("font-size", (ui.size.width / 40));
        }
      });

      el.draggable({ 
        stack: ".stacked",
        stop: function() {
          var z = $(".stacked").css("z-index");
          $(this).css("z-index", z + 1);
        },
        create: function() {
          var z = $(".stacked").css("z-index");
          $(this).css("z-index", z + 1);
        },
        containment: "window" 
      });

      $.each( o, function (key, value) {
        self._setOption(key, value);
      });
      self.resizeTable(o.windowRatio);
    },

    _tableMsg: function (mes) {
      var m = this.element.find(".table-msg.table-mod"),
          t = $("<div />").addClass("table-mes").html(mes),
          b = $("<button />").addClass("modal-ok center").html("OK"),
          w = m.width();
      m.append(
        t,
        b.click(function() {
          m.children().remove();
          m.hide();
        })
      ).show();
    },

    _sweep_pot: function () {
      var self       = this,
          o          = self.options,
          el         = self.element;

      var stacks = el.find(".seat .stack");

      stacks.find(".chip, .size").animate(
        o.pot_css,
        "slow",
        function() {
          stacks.empty();
        }
      );
    },
    buildSelector: function () {
      var self       = this,
          o          = self.options,
          el         = self.element;

      var myHtml = '<option value="none" selected="selected">Select a game</option>';
      $.each( o.gameChoices, function(k,v) {
        myHtml += '<option value="' + k + '">' + v + '</option>';
      });

      var s = $("<select />").addClass("dealer-select").html(myHtml)
      .change(function() {
        $(".dealer-form").submit();
      });

      $("<form />").addClass("dealer-form").append(s)
      .submit(function(event) {    
        event.preventDefault();
        o.pokerMain.main("pick_game", { table_id: o.table_id, game: s.val() });
        s.val("none");
      })
      .hide().appendTo(el);
    },
    _destroy: function () {},
    destroy: function() {},
    _resizeMin: function (res) {
      var self       = this,
          o          = self.options,
          el         = self.element;
      res.off();
      self.resizeTable(o.windowMin);
      res.removeClass("header-icon-min").addClass("header-icon-max").click(function() {
        self._resizeMax(res);
      });
    },
    _resizeMax: function (res) {
      var self       = this,
          o          = self.options,
          el         = self.element;
      res.off();
      self.resizeTable(o.windowMax);
      res.removeClass("header-icon-max").addClass("header-icon-min").click(function() {
        self._resizeMin(res);
      });
    },
    resizeTable: function (ratio, to, le) {

      var o = this.options,
          //l = $("#lobby-main"),
          l = $(window),
          winWidth = l.width(),
          winHeight = l.height(),
          newWidth = winWidth * ratio,
          newHeight = newWidth * o.heightToWidth;

      le = le ? le : ((winWidth - newWidth) / 2);
      to = to ? to : ((winHeight - newHeight) / 2);

      this.element.css({ 
        position: 'absolute',
        width: (newWidth) + 'px', 
        height: (newHeight) + 'px',
        fontSize: (newWidth / 40),
        top: to,
        left: le
      });
    },
    _buildStack: function (chips, stack) {
      var sizes = this.options.chipSizes;
      var i = 0;
      var current_size = sizes[i];
      var dict = {};
      stack.children().remove();
      if (!chips) { return }

      var recur = function(c) {
        if (c >= current_size) {
          c -= current_size;  
          dict[current_size] |= 0;
          dict[current_size]++;
        }
        else {
          current_size = sizes[i++];
          if (!current_size) {
            return;
          }
        }
        recur(c);
      };

      recur(chips * 100);

      var n = 0;
      $.each( sizes, function( i, v ) {
        if ( v in dict ) {
          n++;
          var s = $("<div />").addClass('stack' + n);
          for(j = 0; j < dict[v]; j++) {
            s.append( $("<div />").addClass('chip chip' + v).attr('pos', j) );  
          }
          stack.append( s );
        }
      });
      stack.append(
        $("<div />").addClass('size', chips).html(chips).css('width', n * 4 + '%')
      );
    },

    adjust_pos: function(myseat) {
      var self       = this,
          o          = self.options,
          el         = self.element,
          seats      = el.children(".seat");

      seats.each(function(i) {
        //var new_pos = i - o.login_info[o.login_id].chair;
        var new_pos = i - myseat;
        if ( new_pos < 0 ) {
          new_pos += o.chair_count;
        }
        var seat = $(this);
        var seat_clone = seat.clone(true);
        el.append(seat_clone);

        var clone_stuff = {
          seated: seat_clone.children(".seated-graphic"),
          avitar: seat_clone.children(".avitar-graphic"),
          open: seat_clone.children(".open-graphic"),
          titlebar: seat_clone.children(".titlebar"),
          chips: seat_clone.children(".chips"),
          size: seat_clone.find(".size"),
          button: seat_clone.children(".button"),
          card: seat_clone.children(".card"),
          chip: seat_clone.find(".chip")
        };

        seat.attr('pos', new_pos);
        var seat_stuff = { 
          seated: seat.children(".seated-graphic").css(['left', 'top']),
          avitar: seat.children(".avitar-graphic").css(['left', 'top']),
          open: seat.children(".open-graphic").css(['left', 'top']),
          titlebar: seat.children(".titlebar").css(['left', 'top']),
          chips: seat.children(".chips").css(['left', 'top']),
          size: seat.find(".size").css(['left', 'top']),
          button: seat.children(".button").css(['left', 'top']),
          card: seat.children(".card").css(['left', 'top']),
          chip: seat.find(".chip").css(['left', 'top'])
        };
        seat.hide();

        $.each( clone_stuff, function (key, value) {
          value.animate(
            seat_stuff[key],
            800,
            function() {
              seat_clone.remove();      
              seat.show();
            } 
          );
        });
      });
    },
    table_chips_res: function(v) {
    },
    join_ring_res: function(v) {
      var self = this,
             o = self.options,
            el = self.element;

      if(v.success) {
        self.adjust_pos(v.chair);
      }
    },
    //unjoin_ring_res: function(v) {
      //this.options.login_id = null;
    //},
    notify_join_hydra: function(v) {
      var self = this,
             o = self.options,
            el = self.element;

      $.each( v.hydra_chairs, function (i, val) {
        self.notify_join_table({ 
          login_id: v.login_id,
          chips: v.chips,
          handle: v.handle,
          chair: val,
        });     

      })
    },
    notify_join_table: function(v) {
      var self = this,
             o = self.options,
            el = self.element;

      var seat = el.find(".seat" + v.chair).attr('login_id', v.login_id);
      seat.attr("status", "seated").children(".open-graphic").remove();

      seat.append(
        $("<div />").addClass('seated-clear'),
        $("<div />").addClass('seated-graphic'),
        $("<div />").addClass('avitar-graphic'),
        $("<div />").addClass('chips').html(v.chips),
        $("<div />").addClass('stack'),
        $("<div />").addClass('game-action').hide(),
        $("<div />").addClass('titlebar').html(v.handle)
      );

      o.login_info[v.login_id] = {
        handle: v.handle,
        color: v.color
      };
      o.chair_info[v.chair] = v;
    },
    player_unjoin: function(v) {
      var self = this,
             o = self.options,
            el = self.element;

      delete o.login_info[v.login_id];
      delete o.chair_info[v.chair];
      var seat = el.find(".seat" + v.chair).attr("status", "open");
      seat.children().not(".button, .stack").remove();
    },

    player_snap: function(opts) {
      var self = this,
             o = self.options,
            el = self.element;

      $.each( opts, function (i, v) {
        self.player_update(v);

        // reposition on reconnect
        //if ( o.login_id == v.login_id ) {
        //o.myChair = v.chair
        //}
      });
      //alert('login_info: ' + JSON.stringify(o.login_info));
    },

    player_update: function(opts) {
      var self = this,
             o = self.options,
            el = self.element;

      var seat = el.find(".seat" + opts.chair);
      var fnMap = {
        in_pot_this_round: function(v) {
          //var stack = seat.children('.stack');
          //o.dfd.promise().then( function() {
            var stack = seat.children('.stack');
            self._buildStack(v, stack);
          //});
        },
        cards: function(v) {
          seat.children(".card").remove();
          seat.attr('hole_count', v.length);
          $.each( v, function( i, c ) {
            c = c || 'cb';
            seat.append( 
              //$("<div />").addClass('mv card hole' + i + ' c' + c) 
              $("<div />").addClass("card c" + c).attr({hole: i})
              //$("<div />").addClass('mv card c' + c).attr('hole', i);
            );
          });
          //alert('made hole cards');
        },
        chips: function(v) {
          seat.children(".chips").html(v);
        },
        handle: function(v) {
          o.login_info[opts.login_id].handle = v;
        },
        sit_out: function(v) {},
        is_in_hand: function(v) {}
      };

      //o.login_info[opts.login_id].handle = opts.handle; 
      //$.extend(o.login_info[opts.login_id], opts); 
      $.extend(o.chair_info[opts.chair], opts); 

      $.each( opts, function( k, v ) {
        if (k in fnMap) {
          fnMap[k](v);
        }
      });
    },

    table_snap: function(opts) {
      var self = this,
             o = self.options,
            el = self.element;
      o.dfd.resolve();
      self.table_update(opts);
      $.each( o.chair_info, function( k, v ) {
        if (v.login_id && v.login_id == o.login_id) {
          self.adjust_pos(k);
          return false;
        }
      });
    },

    table_update: function(opts) {
      var self = this,
             o = self.options,
            el = self.element;

      //alert('action called: ' + JSON.stringify(opts) );
      var fnMap = {
        community: function(value) {
          var comm = el.children(".community");
          comm.children().remove();
          $.each( value, function( i, v ) {
            comm.append( $("<div />").addClass('card com' + i + ' c' + v) );
          });
        },
        pot: function(value) {
          var p = el.find(".pot");
          if (value) {
            p.html('Pot: ' + value);
          }
          else {
            p.empty();
          }
        },
        game_choice: function(value) {
          var choice = ': ' + opts.limit + ' ' + o.gameClass[opts.game_choice];
          el.find(".choice-info").html(choice);
          el.attr('game-choice', opts.game_choice);
        },
        round: function(value) {
          o.round = value; 
          el.attr('round', value);
        },
        button: function(value) {
          el.find(".seat .button").remove();
          el.find(".seat" + value).append(  
            $("<div />").addClass("button active")
          );
        },
        valid_act: function(value) {
          o.valid_act = value;
        },
        call_amt: function(value) {
          o.call_amt = parseFloat(value);
        },
        small_bet: function(value) {
          o.small_bet = parseFloat(value);
        },
        max_bet: function(value) {
          o.max_bet = parseFloat(value);
        },
        max_discards: function(value) {
          o.max_discards = value;
        },
        min_discards: function(value) {
          o.min_discards = value;
        },
        max_draws: function(value) {
          o.max_draws = value;
        },
        min_draws: function(value) {
          o.min_draws = value;
        },
        bring: function(value) {
          o.bring = parseFloat(value);
        },
        hide_buttons: function() {
          self._hide_buttons();
        },
        auto_play: function(value) {
          o.auto_play = value;
        },
        action: function(value) {
          o.action = value;
          self._hide_buttons();
          var seats = el.find('.seat').removeClass('active');
          seats.find('.card.selected').removeClass('selected').animate({
            opacity: '1',
            top: '+=2%'
          }, "fast", function() {});
        }
      };

      $.each( opts, function( key, value ) {
        if (key in fnMap) {
          fnMap[key](value);
        }
      });

      if (typeof opts.action == 'number') {
/*
        o.action = opts.action;
        var seats = el.find('.seat').removeClass('active');
        seats.find('.card.selected').removeClass('selected').animate({
          opacity: '1',
          top: '+=2%'
        }, "fast", function() {});
        self._hide_buttons();
        var seat = seats.filter('.seat' + opts.action).addClass('active');
*/
        var seat = el.find('.seat' + opts.action).addClass('active');
        //if ((o.chair_info[o.action].login_id == o.login_id) && !o.auto_play) {
        if (o.chair_info[o.action].login_id == o.login_id) {
          self._show_buttons(opts);
          if (o.max_discards || o.max_draws) {
            seat.children(".card").each(function() {
              var hole = $(this).attr('hole');
              $(this).click(function() {
                self._select_discard(hole);
              });
            });
          }
        }
      }
    },

    _select_discard: function(i) {
      var self = this,
             o = self.options,
            el = self.element;
 
      var seat = el.children(".seat" + o.action);
      var max_select = o.max_discards || o.max_draws;
      //var card = seat.children(".hole" + i);
      var card = seat.children(".card[hole=" + i + "]");
      var select_count = seat.children(".card.selected").length;

      if (card.hasClass('selected')) {
        card.animate({
          opacity: '1',
          top: '+=2%'
        }, "fast", function() {});
        card.removeClass('selected');
      }
      else if (select_count < max_select ) {
        card.animate({
          opacity: '.5',
          top: '-=2%'
        }, "fast", function() {});
        card.addClass('selected');
      }
    },
    move_button: function(opts) {
      var el = this.element;
      var from = el.find('.seat .button');
      var to = $("<div />").addClass("button");
      el.find('.seat' + opts.button).append(to);
      var to_css = to.css(["left", "top"]);
      to.hide();
      from.animate(
        to_css,
        //to.css(["left", "top"]),
        "slow",
        function() {
          //to.addClass("active");
          to.show();
          from.remove();
        }
      );
    },

    notify_post: function(opts) {
      var self = this,
        o = self.options,
        el = self.element;

      var seat = el.children(".seat" + opts.chair);
      self._notify_act(opts.chair, 'Post ' + opts.chips);
      self.player_update({
        chair: opts.chair,
        in_pot_this_round: opts.in_pot
      });
      var chips = seat.children(".chips").html();
      seat.children(".chips").html( parseFloat(chips) - parseFloat(opts.chips) );
    },
    new_game: function(opts) {
      this._clear_table();
    },
//    new_game: function(opts) {
    _clear_table: function(opts) {
      var self = this,
        o = self.options,
        el = self.element;

      self.table_update({ auto_play: false });
      el.find('.pot').empty();
      el.find('.pot-stack').remove();
      el.find(".seat .stack").children().remove();
      el.find('.seat .card').remove();
      el.find('.community').children().remove();
      el.find('.dealer-select').val('none');
    },
    end_game: function(opts) {
      var self = this,
        o = self.options,
        el = self.element;
      el.find(".dealer-form").hide();
      el.find('.seat.active').removeClass('active');
      self._hide_buttons();
      self._sweep_pot();
      //self._clear_table();
    },
    showdown: function(opts) {
      var self = this,
        o = self.options,
        el = self.element;
      self.player_update({ chair: opts.chair, cards: opts.cards });
    },
    high_winner: function(opts) {
      var self = this,
        o = self.options,
        el = self.element;
      //$.when(  o.dfd ).done(function() {
      o.dfd.promise().then(function() {
        self._payout(opts);
      });
    },
    low_winner: function(opts) {
      var self = this,
        o = self.options,
        el = self.element;
      o.dfd.promise().then(function() {
      //$.when( o.dfd ).done(function() {
        setTimeout( function() {
          self._payout(opts);
        }, 800 );
      });
    },
    _payout: function(opts) {
      var self = this,
        o = self.options,
        el = self.element;

      var stack = $("<div/>").addClass("stack pot-stack");
      el.append(stack);
      var winner_stack = el.find(".seat" + opts.chair + " .stack");
      self._buildStack(opts.payout, stack);
      self._buildStack(opts.payout, winner_stack);
      var win_css = winner_stack.find(".chip").first().css(["left", "top"]);
      winner_stack.hide();
      el.find('.pot').empty();
      setTimeout( function() {
        stack.find(".chip, .size").animate(
          win_css,
          "slow",
          function() {
            winner_stack.show();
            stack.remove();
            self.player_update({chair: opts.chair, chips: opts.chips});
          }
        );
      }, 1500 );
    },
    _notify_act: function(chair, msg) {
      var seat = this.element.children(".seat" + chair);
      var h = seat.children(".chips, .titlebar").hide();
      var s = seat.children(".game-action").html(msg).show();
      setTimeout( function() {
        h.show();
        s.hide();
      }, 2000 );
    },

    notify_bet: function(opts) {
      var self = this,
        o = self.options,
        el = self.element;

      var seat = this.element.children(".seat" + opts.chair);
      o.dfd.promise().then( function() {

      self._notify_act(opts.chair, 'Bet');
      self.player_update({
        chair: opts.chair,
        in_pot_this_round: opts.in_pot_this_round
      });
      // var chips = seat.children(".chips").html();
      seat.children(".chips").html( opts.balance );
      //var snd = new Audio("snd/chipsCollide3.ogg"); 
      self.options.betSnd.play();
      });
    },
    notify_check: function(opts) {
      var seat = this.element.children(".seat" + opts.chair);
      this._notify_act(opts.chair, 'Check');
    },
    notify_fold: function(opts) {
      this._notify_act(opts.chair, 'Fold');
      var seat = this.element.children(".seat" + opts.chair);
      seat.children(".card").remove();
    },
    notify_discard: function(opts) {
      var self = this,
        o = self.options,
        el = self.element;

      self._notify_act(opts.chair, 'Discard');
      var seat = el.children(".seat" + opts.chair);
   
      //o.dfd = new jQuery.Deferred();
      var discards = seat.children(".card").filter(function() {
        var h = $(this).attr("hole");
        var index = opts.card_idx.indexOf(parseInt(h));
        if (index >= 0) {
          return true;
        }
        else {
          return false;
        }
      });
      discards.animate(
        o.shoe_css,
        "slow",
        function() {
          $(this).remove();
          var cards = seat.children(".card");
          //seat.children(".card").each(function(i) {
          cards.each(function(i) {
            $(this).attr('hole', i);
          });
          seat.attr('hole_count', cards.length);
        }
      );
    },
    notify_draw: function(opts) {
      var self = this,
        o = self.options,
        el = self.element;
      self._notify_act(opts.chair, 'Draw');
      var seat = el.children(".seat" + opts.chair);
    //var l = seat.children(".card").length;
      $.each (opts.card_map, function (i,v) {
        v = v || 'cb';
        var card = seat.children(".card[hole=" + i + "]");
        var card_css = card.css(["left", "top"]);
        card.animate(
          o.shoe_css,
          "slow",
          function() {
            card.removeClass().addClass("shoe card ccb");
          }
        ).animate(
          card_css,
          "slow",
          function() {
            card.remove();
            seat.append(
              $("<div/>").addClass("card c" + v).attr('hole', i)
            );
          }
        );
      });
      o.cardSnd.play();
    },
    deal_hole: function(opts) {
      var self = this,
        o = self.options,
        el = self.element;

      //$.extend(o.login_info[opts.login_id], opts);
      $.extend(o.chair_info[opts.chair], opts);
      //self.player_update({cards: opts.cards});
      var seat = el.children(".seat" + opts.chair);
      var l = seat.children(".card").length;
      seat.attr('hole_count', opts.cards.length + l);
      $.each (opts.cards, function (i,v) {
        v = v || 'cb';    
        var shoe = $("<div />").addClass("shoe card ccb");
        var card = $("<div />").addClass('card').attr('hole', l++);
        seat.append(card);
        var card_css = card.css(["left", "top", "margin-left", "margin-top"]);
        el.append(shoe);
        shoe.animate(
          card_css,
          "slow",
          function() {
            card.addClass('c' + v);
            shoe.remove();
          }
        );
      });
      //seat.attr('hole_count', l);
      o.cardSnd.play();
    },
    table_opts_res: function(opts) {
      var self = this,
        o = self.options,
        el = self.element;
 
      var fnMap = {
        sit_out: function(value) {},
        wait_bb: function(value) {},
        auto_rebuy: function(value) {},
        auto_muck: function(value) {}
      };
      $.each( opts, function( k, v ) {
        if (k in fnMap) {
          fnMap[k](v);
        }
      });
    },
    pick_game_res: function(opts) {
      if (opts.success) {
        this.element.find(".dealer-form").hide();
      }
    },
    bet_res: function(opts) {
      if (opts.success) {
        this._hide_buttons();
      }
    },
    check_res: function(opts) {
      if (opts.success) {
        this._hide_buttons();
      }
    },
    fold_res: function(opts) {
      if (opts.success) {
        this._hide_buttons();
      }
    },
    discard_res: function(opts) {
      if (opts.success) {
        this._hide_buttons();
      }
    },
    draw_res: function(opts) {
      if (opts.success) {
        this._hide_buttons();
      }
    },

    _hide_buttons: function(opts) {
      var self = this,
        o = self.options,
        el = self.element;

      //el.find(".seat" + o.login_info[o.login_id].chair + " .card").off('click');
      el.find(".seat .card").off('click');
      el.find(".action").off().hide();
      el.find(".bet-slider").hide();
      el.find(".bet-amount").hide();
    },
    _show_buttons: function(opts) {
      var self = this,
        o = self.options,
        el = self.element;

      var seat = el.find(".seat.active");
      //var my_seat = el.find(".seat" + o.login_info[o.login_id].chair);

      //var acts = el.find(".action");
      var s = el.find(".bet-slider");
      var a = el.find(".bet-amount");
      //var smallBet = o.small_bet;
      var myChips = o.chair_info[o.action].chips;
      //var myChips = parseInt(
      //  el.find(".seat" + o.login_info[o.login_id].chair + " .chips").html()
      //);
      //var callAmt = myChips > opts.call_amt ? opts.call_amt : myChips;
      //var callAmt = myChips > o.call_amt ? o.call_amt : myChips;

      var minRaise;

      if (o.hydra_flag) {
        self.adjust_pos(o.action);
      }
      //if (myChips > callAmt) {
      if (myChips > o.call_amt) {
        minRaise = o.call_amt + o.small_bet + ( (o.call_amt + o.small_bet) % o.small_bet );
        minRaise = minRaise > myChips ? myChips : minRaise;
        minRaise = minRaise > o.max_bet ? o.max_bet : minRaise;
      }
      
      var fnMap = {
        bet: function(i) {
          if(o.call_amt) {
            var b1 = el.find(".action[no='1']");
            b1.css('padding-top', '.3%');
            b1.html('Call <br />' + o.call_amt);
            b1.click(function() { 
              o.pokerMain.main("bet", { table_id: o.table_id, chips: o.call_amt });
 
              //self._hide_buttons();
            });
            b1.show();
          }
          if(minRaise) {
            var b2 = el.find(".action[no='2']");
            var s = el.find(".bet-slider");
            var a = el.find(".bet-amount");

            b2.css('padding-top', '.3%');
            b2.html('Raise <br /><div class="raise"></div>');
            b2.click(function() { 
              o.pokerMain.main("bet", { table_id: o.table_id, chips: a.val() });
            });

            var r = el.find(".raise");

            s.slider({
              value: minRaise,
              min: minRaise,
              max: o.max_bet,
              step: o.small_bet,
              slide: function( event, ui ) {
                a.val( ui.value );
                r.html( ui.value ); 
              }
            });
            a.val( s.slider( "value" ) );
            r.html( s.slider("value") );
            if (minRaise < o.max_bet) {
              s.show();
              a.show();
            }
            b2.show();
          }
        },
        check: function(i) {
          var b = el.find(".action[no='1']");
          //var b = el.find(".action[no='" + i + "']");
          b.css('padding-top', '2%');
          b.html('Check');
          b.click(function() { 
            o.pokerMain.main("check", { table_id: o.table_id });
            //self._hide_buttons();
          });
          b.show();
        },
        fold: function(i) {
          var b = el.find(".action[no='0']");
          //var b = el.find(".action[no='" + i + "']");
          b.css('padding-top', '2%');
          b.html('Fold');
          b.click(function() { 
            o.pokerMain.main("fold", { table_id: o.table_id });
            //self._hide_buttons();
          });
          b.show();
        },
        discard: function() {
          var index = parseInt(o.min_discards) > 0 ? 1 : 2;
          //var index = parseInt(opts.min_discards) > 0 ? 1 : 2;
          var b = el.find(".action[no='" + index + "']");
          //var b = el.find(".action[no='" + i + "']");
          b.css('padding-top', '2%');
          b.html('Discard');
          b.click(function() {
            var cards = seat.find(".card");
            var selected = [];
            cards.each(function() {
              if ($(this).hasClass('selected')) {
                var hole = $(this).attr('hole');
                selected.push(hole);
              }
            }); 
            if (selected.length <= o.max_discards && selected.length >= o.min_discards) {
              o.pokerMain.main("discard", { table_id: o.table_id, card_idx: selected });
            }
            //self._hide_buttons();
          });
          b.show();
        },
        draw: function() {
          //var index = parseInt(opts.min_draws) > 0 ? 1 : 2;
          //var index = parseInt(o.min_draws) > 0 ? 1 : 2;
          var b = el.find(".action[no='2']");
          //var b = el.find(".action[no='" + i + "']");
          b.css('padding-top', '2%');
          b.html('Draw');
          b.click(function() {
            var cards = seat.find(".card");
            var selected = [];
            cards.each(function(i) {
              if ($(this).hasClass('selected')) {
                var hole = $(this).attr('hole');
                selected.push(hole);
              }
            });
            if (selected.length <= o.max_draws && selected.length >= o.min_draws) {
              o.pokerMain.main("draw", { table_id: o.table_id, card_idx: selected });
            }
            //self._hide_buttons();
          });
          b.show();
        },
        choice: function() {
          el.find(".dealer-form").show();
        },
        bring: function() {
          var b1 = el.find(".action[no=1]")
          var b2 = el.find(".action[no=2]");
          b1.css('padding-top', '.3%');
          b1.html('Bring <br />' + o.bring);
          b2.css('padding-top', '.3%');
          b2.html('Bring <br />' + o.small_bet);
          b1.click(function() {
            o.pokerMain.main("bet", { table_id: o.table_id, chips: o.bring });
          });
          b1.show();
          b2.click(function() {
            o.pokerMain.main("bet", { table_id: o.table_id, chips: o.max_bet });
          });
          b2.show();
        }
      };
      $.each(o.valid_act, function(i, v) {
        if (v in fnMap) { fnMap[v](i) }
      });
    },
    notify_pick_game: function(opts) {
      var self = this,
        o = self.options,
        el = self.element;

      self.table_update(opts);
    },
    notify_message: function(opts) {
      var self = this,
        o = self.options,
        el = self.element;
      var from = o.login_info[opts.from] || o.login_info['k'];
      var handle = from.handle;
      o.chatBox.append(
        $("<div />").addClass("chat-msg").append(
          $("<a />").addClass("chat-handle").html(handle).css("color", from.color),
          $("<span />").html(': ' + opts.message)
        )
      );
      o.chatBox.animate({scrollTop: o.chatBox[0].scrollHeight});
    },
    begin_new_action: function(opts) {
      var self = this,
      o = self.options,
      el = self.element;

      o.dfd.promise().then( function() {
        el.find(".seat.active").removeClass("active");
        el.find(".seat" + opts.action).addClass("active"); 
        self.table_update({
          small_bet: opts.small_bet,
          max_bet: opts.max_bet,
          valid_act: opts.valid_act,
          max_discards: opts.max_discards,
          min_discards: opts.min_discards,
          max_draws: opts.max_draws,
          min_draws: opts.min_draws,
          bring: opts.bring,
          call_amt: opts.call_amt,
          action: opts.action
        });  
      });
    },
    begin_new_round: function(opts) {
      var self = this,
        o = self.options,
        el = self.element;

      self._sweep_pot();
/*
      var stacks = el.find(".seat .stack");

      stacks.find(".chip, .size").animate( 
        o.pot_css,
        "slow",
        function() {
          stacks.empty();
        }
      );
*/
      self.table_update({
        pot: opts.pot, 
        auto_play: opts.auto_play,
        round: opts.round  
      });  

      o.dfd = new jQuery.Deferred();
      setTimeout( function() {
        o.dfd.resolve();
      }, 600 );
    },
    deal_community: function(opts) {
      var self = this,
        o = self.options,
        el = self.element;

      var comm = el.find(".community");
      var stacks = el.find(".seat .stack .chip");
      o.dfd.promise().then( function() { 

        var l = comm.children().length;
        $.each (opts.community, function (i,v) {
          var shoe = $("<div />").addClass("shoe card c" + v);
          var card = $("<div />").addClass('card com' + l++ + ' c' + v);
          el.append(shoe); 
          comm.append( card );
          var card_css = card.css(["left", "top"]);
          card.hide();
          shoe.animate( 
            card_css,
            //card.css(["left", "top"]), 
            "slow", 
            function() { 
              card.show();
              //card.addClass('c' + v); 
              shoe.remove(); 
            } 
          );
          o.cardSnd.play();
        }) 
      }); 
      stacks.children().remove();
    },
    _setOption: function (key, value) {
      var self = this,
        o = self.options,
        el = self.element;

      o[key] = value;
/*
      var fnMap = {
      };

      if (key in fnMap) {
        o[key] = value;
        fnMap[key]();
      }
*/
    }

  }); 
})( jQuery, window, document );
