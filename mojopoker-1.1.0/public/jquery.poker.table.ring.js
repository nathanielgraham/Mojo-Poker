;(function ( $, window, document, undefined ) {

  $.widget('poker.table_ring', $.poker.table, {
    _create: function() {
      var self = this,
             o = self.options,
            el = self.element;

      self._super();
      el.append(
        self._buildBuy(),
        $("<div />)").addClass("leave-all").click(function() {
          o.pokerMain.main("unjoin_ring", { table_id: o.table_id });
        })
      );
      el.find(".header-icon-close").click( function() {
        o.pokerMain.main("unjoin_ring", { table_id: o.table_id });
      });
    },
    unjoin_ring_res: function(v) {
      var self = this,
             o = self.options,
            el = self.element;

      el.find(".leave-all").hide();
      el.find(".open-graphic").show();
    },
    notify_join_table: function(v) {
      var self = this,
             o = self.options,
            el = self.element;

      self._super(v);
      if (v.login_id == o.login_id) {
        var seat = el.find(".seat" + v.chair);
        seat.append(
          $("<div />").addClass("menu").append(
          $("<button />").addClass("get-chips menuitem").html('Get Chips').click(function() {
            seat.children(".menu").fadeToggle("fast");
            self.tableBuy(v.chair, true);
          }), 
          $("<button />").addClass("leave-table menuitem").html('Leave Table').click(function() {
            o.pokerMain.main("unjoin_ring", { table_id: o.table_id, chair: v.chair });
            seat.children(".menu").fadeToggle("fast");
          })
         )
        );
        seat.children('.seated-clear').click( function() {
          var m = seat.children(".menu").fadeToggle("fast");
          clearTimeout(o.menutimer);
          o.menutimer = setTimeout(function() {
            m.hide();
          }, 5000);
        });
        el.find(".leave-all").show();
        el.find(".open-graphic").hide();
      }
    },
    player_unjoin: function(v) {
      var self = this,
             o = self.options,
            el = self.element;

      this._super(v);
      var seat = el.find(".seat" + v.chair).attr("status", "open");
      seat.append(
        $("<div />").addClass("open-graphic").click( function() {
          var j = $("#lobby-main").lobby("option", "myData");
          alert(JSON.stringify(j));
          if (j) {
            self.tableBuy(v.chair, false);
          }
          else {
            self._tableMsg("Not enough chips.");
          }
        })
      );
    },
    _buildBuy: function () {
      var self = this,
             o = self.options,
            el = self.element,
           sld = $("<div />").addClass("opt-sld")
                 .slider({
                   value: (o.table_min + o.table_max) / 2,
                   min: o.table_min,
                   max: o.table_max,
                   slide: function( event, ui ) {
                     amt.val( ui.value );
                   }
                 }),
           amt = $("<input />").addClass("opt-amt").attr({
                   name: "optra",
                   type: "text",
                   value: sld.slider( "value" )
                 });

      var f = $("<form />").append(
        $("<div />").addClass("opt-amtl").html("Amount:"),
        amt,
        sld
      );

      var m = $("<div />").addClass("table-buy table-mod");
      return m.append(
        //$("<div />").addClass("opt-head").html("Buy in"),
        $("<div />").addClass("opt-head"),
        $("<div />").addClass("opt-bank").html("My Bankroll:"),
        $("<div />").addClass("opt-bval"),
        $("<div />").addClass("opt-rebuy").html("Auto-Rebuy:"),
        $("<div />").addClass("opt-reval bool").click(function() {
          var $this = $(this);
          $this.toggleClass("on");
          if ($this.hasClass("on")) { 
            $this.html("On");
          }
          else {
            $this.html("Off");
          }
        }).click(),
        f,
        $("<button />").addClass("modal-ok")
        .html("OK").click(function() {
          f.submit();
        }),
        $("<button />").addClass("modal-cancel")
        .html("Cancel").click(function() {
          m.hide();
        })
      );
    },
    tableBuy: function (c, add) {
      var self = this,
             o = self.options,
            el = self.element,
             m = el.find(".table-buy"),
             //m = el.find(".table-buy.table-mod"),
          head = m.find(".opt-head"),
           bnk = m.find(".opt-bval"),
           amt = m.find(".opt-amt"),
           sld = m.find(".opt-sld");

      var chips = $("#lobby-main").lobby("option", "myData.chips");
      //var roll = chips && o.director_id in chips ? chips[ o.director_id ] : 0;
      var roll = chips ? chips : 0;
      var max = roll > o.table_max ? o.table_max : roll;
      sld.slider("option", "max", max);
      bnk.html(roll);
      var h = add ? "Get Chips" : "Buy in";
      head.html(h);
 
      m.find("form").off().submit(function(event) {
        event.preventDefault();
        var arb = m.find(".opt-reval").hasClass("on") ? amt.val() : 0;

        if (add) { // get chips
          //head.html("Get Chips");
          $("#poker-main").main("table_opts", { auto_rebuy: arb });
          $("#poker-main").main("table_chips", { chips: amt.val(), table_id: o.table_id, chair: c });
        }
        else { // join table
          //head.html("Buy in");
          var parm = {
            chips: amt.val(),
            table_id: o.table_id,
            chair: c,
            auto_rebuy: arb 
          };
          $("#poker-main").main("join_ring", parm);
        }
      });
      m.show();
    },
    table_chips_res: function(v) {
      var self = this,
             o = self.options,
            el = self.element;

      self._super(v);
      el.find(".table-buy").hide();
      if (!v.success) {
        self._tableMsg(v.message);
      }
    },
    join_ring_res: function(v) {
      var self = this,
             o = self.options,
            el = self.element;

      self._super(v);
      el.find(".table-buy").hide();
      if (!v.success) {
        self._tableMsg(v.message);
      }
    }
  }); 
})( jQuery, window, document );
