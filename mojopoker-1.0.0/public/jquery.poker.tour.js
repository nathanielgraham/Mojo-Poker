;(function ( $, window, document, undefined ) {

  $.widget('poker.tour', {
 
    options: {
      heightToWidth: 3 / 4,
      windowRatio: 1 / 2,
      windowMin: 1 / 3,
      windowMax: 15 / 20,
      pidData: {},
      tidData: {},
      colData: {
        1: [ 'Table', 'int' ],
        2: [ 'Players', 'int' ],
        3: [ 'Large', 'int' ],
        4: [ 'Small', 'int' ],
        5: [ 'Player', 'string' ],
        6: [ 'Chips', 'int' ],
        7: [ 'Rank', 'int' ]
      }
    },
    _create: function() {
             
      var self = this,
             o = self.options,
            el = self.element;

      //o.cardSnd = new Audio("snd/cardPlace3.ogg");
      self._setOptions({ 
        pokerLobby: $("#poker-lobby"),
        pokerMain: $("#poker-main") 
      });
      //o.pokerMain = $("#poker-main");
      //o.pokerLobby = $("#poker-lobby");

      el.addClass("ui-widget ui-front stacked tour " + o.game_class).attr({ 'chair-count': o.chair_count, 'game-choice': o.game_class }).append(  
        $("<div/>").addClass("header-icon header-icon-resize header-icon-max").click( function() {
          self._resizeMax($(this));
        }),

        $("<div/>").addClass("header-icon header-icon-close").click( function() {
          o.pokerMain.main("unwatch_tour", { tour_id: o.tour_id });
        }),
        $("<div />").addClass("tour-header"),
        $("<div />").addClass("tour-logo"),
        //$("<div />").addClass("tour-class").html("NL Holdem"),
        $("<div />").addClass("tour-class"),
        $("<div />").addClass("tour-buyin"),
        $("<div />").addClass("tour-state"),
        $("<div />").addClass("tour-header"),
        $("<div />").addClass("tour-sum").append(
          $("<div />").addClass("tour-start"),
          $("<div />").addClass("tour-end"),
          $("<div />").addClass("tour-enroll"),
          $("<div />").addClass("tour-reg").html("Register").hide(),
          $("<div />").addClass("tour-prizes")
        ),
        $("<div />").addClass("tour-tables").append(
          self._buildTable([1,2,3,4])
        ),
        $("<div />").addClass("tour-detail").append(
          $("<button />").addClass("tour-observe").html("Observe Table").hide()
        ),
        $("<div />").addClass("tour-players").append(
          self._buildTable([5,6,7])
        )
      );
      
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
      self.resizeBox(o.windowRatio);
      self.tour_update(o);
    },
    _buildTable: function (cols) {
      var self = this,
          o = self.options,
          el = self.element;

      var myHtml = '';
      $.each( cols, function(i,v) {
        var n = o.colData[v][0]; // name
        var t = o.colData[v][1]; // typr
        myHtml += '<th data-sort-dir="asc" data-sort="' + t + '">' + n + '</th>';
      });

      return $("<div />").addClass("table-box").append(
        $("<table />").append(
          $("<thead />").append(
            $("<tr>").html(myHtml)
          ),
          $("<tbody />")
        )
        .stupidtable().bind('aftertablesort', function (event, data) {
        // data.column - the index of the column sorted after a click
        // data.direction - the sorting direction (either asc or desc)

          $this = $(this);
          $this.find("tbody tr:visible:first").trigger('click');
          var th = $this.find("th");
          th.find(".arro").remove();
          var arrow = data.direction === "asc" ? "↑" : "↓";
          th.eq(data.column).append('<span class="arro">' + arrow +'</span>');
        })
      );
    },
    tour_update: function (opts) {
      var self       = this,
          o          = self.options,
          el         = self.element;

      var fnMap = {
        tourData: function(v) {
          var b = v.entry_fee + v.buy_in;
          el.find(".tour-header").html(b + ' ' + v.desc);
          //el.find(".tour-class").html(v.desc + ' ' + v.class_name);
          el.find(".tour-class").html(v.desc);
          //el.find(".tour-start").html("Start " + v.start);
          el.find(".tour-buyin").html("Buy-In: " + v.buy_in + ' + ' + v.entry_fee);
        },
        prizes: function(v) {
          var p = el.find(".tour-prizes");
          $.each( v, function( i, v ) {
            p.append(
              $("<div>").append(
                $("<span>").html(i + 1),
                $("<span>").html(v)
              )
            );
          });
        },

        del_plrs: function(v) {
          var t = el.find(".tour-players tbody");
          $.each( v, function( i, pid ) {
            delete o.pidData[pid];
            t.children('tr[pid=' + pid + ']').remove();
          });
        },
        add_plrs: function(v) {

          //o.pidData = v;
          //$.extend(o.pidData, v);

          var t = el.find(".tour-players tbody");
          //var tt = el.find(".tour-tables tbody");
          //var td = el.find(".tour-detail");

          $.each( v, function( pid, data ) {
            o.pidData[pid] = data;
            t.children('tr[pid=' + pid + ']').remove();
            t.append(
              $("<tr>").attr('pid', pid).append(
                $("<td>").html(data['handle']),
                $("<td>").html(data['chips']),
                $("<td>") // rank
              )
            );
          });
          // calculate table data
          //alert(JSON.stringify(o.tidData));
        },
        seat_plrs: function(v) {

        },
        unseat_plrs: function(v) {

        },
        end_time: function(v) {
          if (v) {
            var dt = (new Date(v * 1000 + o.epochDiff)).toString().split(/\s/);
            var tm = dt[4].split(':');
            var et = dt[1] + ' '  + dt[2] + ' ' + tm[0] + ':' + tm[1];
            el.find(".tour-end").html('Ended: ' + et);
          }
        },
        start_time: function(v) {
          var dt = (new Date(v * 1000 + o.epochDiff)).toString().split(/\s/);
          var tm = dt[4].split(':');
          var st = dt[1] + ' '  + dt[2] + ' ' + tm[0] + ':' + tm[1];
          el.find(".tour-start").html('Started: ' + st);
        },
        state: function(v) {
          el.find(".tour-state").html('Tournament ' + o.gameState[v]);
        },
        enrolled: function(v) {
          el.find(".tour-enroll").html('Enrolled: ' + v);
        }
      };

      $.each( opts, function( k, v ) {
        if (k in fnMap) {
          fnMap[k](v);
        }
      });
    },
    _destroy: function () {},
    destroy: function() {},
    _resizeMin: function (res) {
      var self       = this,
          o          = self.options,
          el         = self.element;
      res.off();
      self.resizeBox(o.windowMin);
      res.removeClass("header-icon-min").addClass("header-icon-max").click(function() {
        self._resizeMax(res);
      });
    },
    _resizeMax: function (res) {
      var self       = this,
          o          = self.options,
          el         = self.element;
      res.off();
      self.resizeBox(o.windowMax);
      res.removeClass("header-icon-max").addClass("header-icon-min").click(function() {
        self._resizeMin(res);
      });
    },
    resizeBox: function (ratio, to, le) {

      var o = this.options,
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
