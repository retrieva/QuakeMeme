/*
 * scripts.js
 */

var pages = {
	// アップデートタイマー
	// object
	update_tid: null,

	// アップデートインターバル
	// int
	update_sec: null,

	// アップデートURL
	// string
	update_url: null,

	// アップデート中
	// boolean
	updating: false,

	// アップデート
	update: function (force) {
		// アップデート中なら停止
		if (this.updating) {
			return false;
		}
		this.updating = true;

		var $pages = $('.pages');
		if (force) {
			$pages.empty(); //< リセットをかける
		}
		var $first = $('.pages .page:first-child');

		$pages.append($('<div>').addClass('loading')); //< インディケータの表示

		var that = this;
		$.getJSON(this.update_url, {
			cid: this.option('cid'),
			type: this.option('type')
		}, function (json) {
			$pages.find('.loading').remove();
			var $tmpl_page = $('#tmpl-page'),
			    last_id = that.option('last_id');

			$.each(json.pages, function (i, page) {
				page.original_url = page.original_url || page.url;

				// タイトルが空の場合
				page.title = page.title || page.url;
				// ツイートボタン
				var tweet_data = {
					url: page.url,
					via: 'quakememe http://quakememe.jp/',
					lang: 'ja'
				};
				if (page.title !== page.url) {
					tweet_data.text = page.title;
				}
				page.tweet_url = 'http://twitter.com/share?' + $.param(tweet_data);
				// 検索用リンクの生成
				page.search_url = 'http://search.twitter.com/search?' + $.param({ q: page.url });
				// ドメイン部分の抽出
				page.domain = (page.original_url.match(/\:\/\/([^\/]+)/) || [])[1] || '';
				// 画像用URLの生成
				page.thumb_url = that.get_thumb(page.original_url);

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

			that.option('last_id', json.pages[0].id);

			$.getScript('http://platform.twitter.com/widgets.js');
		}).error(function (xhr, msg) {
			if (msg === 'error' && xhr.status === 404) {
				$('<p>').addClass('notfound').text('このカテゴリのウェブページはまだありません。').appendTo('.pages');
				return;
			}
			that.trace(msg, xhr);
		}).complete(function () {
			$pages.find('.loading').remove();
			that.updating = false;
		});

		return true;
	},

	// 定期アップデートの初期化
	update_init: function () {
		if (this.update_tid) {
			clearInterval(this.update_tid);
		}
		var that = this;
		this.update_tid = setInterval(function () {
			that.update(true);
		}, this.update_sec * 1000);
	},

	// サムネイルの取得
	get_thumb: function (url) {
		var m;
		if (m = /http:\/\/www\.jma\.go\.jp\/jp\/quake\/(\d+-\d+)\.html/.exec(url)) {
			return 'http://www.jma.go.jp/jp/quake/images/japan/' + m[1] + '.png';
		}
		if (m = /^http:\/\/twitpic\.com\/(\w+)/.exec(url)) {
			return 'http://twitpic.com/show/thumb/' + m[1];
		}
		if (m = /^http:\/\/movapic\.com\/pic\/(\w+)$/.exec(url)) {
			return 'http://image.movapic.com/pic/t_' + m[1] + '.jpeg';
		}
		if (m = /^http:\/\/f\.hatena\.ne\.jp\/([\w\-]+)\/(\d{8})(\w+)$/.exec(url)) {
			return 'http://f.hatena.ne.jp/images/fotolife/' + m[1].charAt(0) + '/' + m[1]
			     + '/' + m[2] + '/' + m[2] + m[3] + '_120.jpg';
		}
		/*
		if (m = /^(http:\/\/[\w\-]+\.tumblr\.com\/)post\/(\d+)/.exec(url)) {
			$.getJSON(m[1] + 'api/read/json?id=' + m[2], function (json) {
				var url = json.posts[0]['photo-url-75'];
				if (!url) return;
				return url;
			});
			return;
		}
		*/
		if (/^http:\/\/yfrog\.com\/\w+$/.test(url)) {
			return url + '.th.jpg';
		}
		/*
		if (m = /^http:\/\/(?:www\.flickr\.com\/photos\/[\w\-@]+\/(\d+)|flic\.kr\/p\/(\w+)$)/.exec(url)) {
			var fid = m[1], m2 = m[2];
			if (m2) {
				var base58 = '123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ';
				fid = 0;
				for (var i = m2.length, n = 1; i; i--, n *= 58) {
					fid += base58.indexOf(m2.substr(i - 1, 1)) * n;
				}
			}
			$.getJSON('http://www.flickr.com/services/rest?method=flickr.photos.getInfo' +
					'&jsoncallback=?&format=json&api_key=9bc57a7248847fd9a80982989e80cfd0&photo_id=' + fid,
					function(json) {
						var p = json.photo;
						if (!p) return;
						return 'http://farm'+json.farm+'.static.flickr.com/'+json.server+'/'+
									json.id+'_'+json.secret+'_s.jjson.', _url);
					});
			return;
		}
		*/
		if (/^(http:\/\/plixi.com\/p\/\d+)/.test(url)) {
			return 'http://api.plixi.com/api/TPAPI.svc/imagefromurl?size=thumbnail&url=' + url;
		}
		if (m = /^http:\/\/img.ly\/(\w+)/.exec(url)) {
			return 'http://img.ly/show/thumb/' + m[1];
		}
		if (m = /^http:\/\/ow.ly\/i\/(\w+)/.exec(url)) {
			return 'http://static.ow.ly/photos/thumb/' + m[1] + '.jpg';
		}
		if (/^(http:\/\/gyazo.com\/\w+\.png)/.test(url)) {
			return 'http://gyazo-thumbnail.appspot.com/thumbnail?url=' + url;
		}
		if (m = /^http:\/\/(?:www\.youtube\.com\/watch\?.*v=|youtu\.be\/)([\w\-]+)/.exec(url)) {
			return 'http://i.ytimg.com/vi/' + m[1] + '/default.jpg';
		}
		if (m = /^http:\/\/(?:www\.nicovideo\.jp\/watch|nico\.ms)\/([a-z][a-z])(\d+)$/.exec(url)) {
			if (m[1] === 'lv') return;
			return 'http://tn-skr' + (parseInt(m[2]) % 4 + 1) + '.smilevideo.jp/smile?i=' + m[2];
		}
		if (m = /^(http:\/\/instagr\.am\/p\/[\w\-]+)\/?$/.exec(url)) {
			return m[1] + '/media/?size=t';
		}
		if (/^(http:\/\/picplz.com\/\w+)/.test(url)) {
			return url + '/thumb/150';
		}
		if (m = /^http:\/\/photozou\.jp\/photo\/show\/\d+\/(\d+)/.exec(url)) {
			return 'http://art' + Math.floor(Math.random() * 40 + 1) + '.photozou.jp/bin/photo/' + m[1] + '/org.bin?size=120';
		}
	},

	// オプションデータの取得
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

	// デバッグ用
	trace: function () {
		if (window.console && $.isFunction(console.log)) {
			console.log.apply(console, arguments);
		}
	}
};

$(function ($) {

	pages.update_sec = pages.option('interval');
	pages.update_url = pages.option('contents_url');

	if (!pages.update_url) return;

	pages.update(true);
	pages.update_sec && pages.update_init();

	$('.page .meta .share a').live('click', function () {
		var w = 550, h = 450, sw = screen.width, sh = screen.height,
		    x = Math.round((sw / 2) - (w / 2)), y = sh > h ? Math.round((sh / 2) - (h / 2)) : 0;
		var d = window.open(this.href, 'twitter_tweet', 'left=' + x + ',top=' + y + ',width=' + w + ',height=' + h + ',personalbar=0,toolbar=0,scrollbars=1,resizable=1');
		if (d) {
			d.focus();
			return false;
		}
	});

});
