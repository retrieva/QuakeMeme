/*
 * scripts.js
 */

var pages = {
	// アップデートタイマー
	update_tid: null,
	// アップデートインターバル
	update_sec: null,
	// アップデートURL
	update_url: null,

	// アップデート中
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

		$pages.append($('<div>').addClass('loading'));

		var that = this;
		$.getJSON(this.update_url, {
			cid: this.option('cid'),
			type: this.option('type')
		}, function (json) {
			$pages.find('.loading').remove();
			var $tmpl_page = $('#tmpl-page'),
			    last_id = that.option('last_id');
			if (json.pages.length) {
				$.each(json.pages, function (i, page) {
					page.search_url = 'http://search.twitter.com/search?' + $.param({ q: page.url });
					if (page.count > 200) {
					//	page.thumb_url = 'http://img.simpleapi.net/small/' + page.url;
					}
					// page.thumb_url = page.image_url.length ? page.image_url[page.image_url.length - 1] : null;
					var $page = $tmpl_page.tmpl(page);
					if (!$first.length) {
						$page.appendTo('.pages');
					}
					else {
						$page.insertBefore($first);
					}
				});
			}
			else {
				$('<p>').addClass('notfound').text('このカテゴリのウェブページはまだありません。').appendTo('.pages');
			}
			that.option('last_id', json.pages[0].id);
		}).error(function (xhr, msg) {
			that.trace(msg, xhr);
		}).complete(function () {
			$pages.find('.loading').remove();
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
			that.update(true);
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
	},
	trace: function () {
		if (window.console && $.isFunction(console.log)) {
			console.log.apply(console, arguments);
		}
	}
};

$(function ($) {

	pages.update_sec = pages.option('interval') || 60;
	pages.update_url = pages.option('contents_url');

	if (!pages.update_url) return;

	pages.update(true);
	pages.update_init();

});
