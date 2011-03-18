/*
 * scripts.js
 */

var pages = {
	update_tid: null,
	update_sec: null,
	update_url: 'http://ec2-175-41-160-220.ap-southeast-1.compute.amazonaws.com/api/get_contents?callback=?',
	updating: false,
	update: function (force) {
		if (this.updating) {
			return false;
		}
		this.updating = true;

		var $pages = $('.pages');
		if (force) {
			$pages.empty();
		}
		var $first = $('.pages .page:first-child');

		var that = this;
		$.getJSON(this.update_url, {
			cid: pages.option('cid'),
			type: pages.option('type')
		}, function (json) {
			var $tmpl_page = $('#tmpl-page'),
			    last_id = that.option('last_id');
			$.each(json.pages, function (i, page) {
				var $page = $tmpl_page.tmpl(page);
				if (!$first.length) {
					$page.appendTo('.pages');
				}
				else {
					$page.insertBefore($first);
				}
			});
			that.option('last_id', json.pages[0].id);
		}).complete(function () {
			that.updating = false;
		});

		return true;
	},
	update_init: function () {
		if (this.update_tid) {
			clearInterval(this.update_tid);
		}
		var that = this;
		this.update_tid = setInterval(function () {
			that.update();
		}, this.update_sec * 1000);
	},
	option: function (name, value) {
		var node = document.options[name];
		if (!node) {
			return null;
		}
		if (value == null) {
			value = node.value;
			if (!/\D/.test(value)) {
				return parseFloat(value);
			}
			return value;
		}
		node.value = value;
	}
};

$(function ($) {

	pages.update_sec = pages.option('interval') || 60;

	pages.update(true);
	//pages.update_init();

});
