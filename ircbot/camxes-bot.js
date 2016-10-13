var config = {
  server: 'irc.freenode.net',
  nick: 'gentufa',
  options: {
    channels: ['#lojban', '#ckule', '#balningau'],
    debug: false
  }
};

var irc = require('irc');
var client = new irc.Client(config.server, config.nick, config.options);

client.addListener('message', function(from, to, text, message) {
    processor(client, from, to, text, message);
});

var camxes = require('../camxes.js');
var camxes_beta = require('../camxes-beta.js');
var camxes_cbm = require('../camxes-beta-cbm.js');
var camxes_ckt = require('../camxes-beta-cbm-ckt.js');
var camxes_exp = require('../camxes-exp.js');
var camxes_morpho = require('../camxes-morpho.js');
var camxes_pre = require('../camxes_preproc.js');
var camxes_post = require('../camxes_postproc.js');

function make_regexps(nick) {
    return {
        coi:  new RegExp("(^| )coi la \\.?"  + nick + "\\.?"),
        juhi: new RegExp("(^| )ju'i la \\.?" + nick + "\\.?"),
        kihe: new RegExp("(^| )ki'e la \\.?" + nick + "\\.?")
    };
}

var processor = function(client, from, to, text, message) {
  if (!text) return;
  var sendTo = from; // send privately
  if (to.indexOf('#') > -1) {
    sendTo = to; // send publicly
  }
  if (sendTo == to) {  // Public
    if (text.match(/^<(.*?)>: /, '') !== null) { // Dealing with Slack
      from = text.match(/^<(.*?)>: /,'')[1];
      text = text.replace(/^<.*?>: /,"");
    }
    var regexps = make_regexps(config.nick);
    if (text.indexOf(config.nick + ": ") == '0') {
      text = text.substr(config.nick.length + 2);
      var ret = extract_mode(text);
      client.say(sendTo, run_camxes(ret[0], ret[1], ret[2]));
    } else if (text.search(regexps.coi) >= 0) {
      client.say(sendTo, "coi");
    } else if (text.search(regexps.juhi) >= 0) {
      client.say(sendTo, "re'i");
    } else if (text.search(regexps.kihe) >= 0) {
      client.say(sendTo, "je'e fi'i");
    }
  } else {  // Private
	var ret = extract_mode(text);
    client.say(sendTo, run_camxes(ret[0], ret[1], ret[2]));
  }
};

function extract_mode(input) {
  ret = [input, "", "std"];
  flag_pattern = "[+-]\\w+"
  match = input.match(new RegExp("^\\s*((?:" + flag_pattern + ")+)(.*)"))
  if (match != null) {
    ret[0] = match[2];
    if (ret[0].length > 0 && ret[0][0] == " ")
        ret[0] = ret[0].substring(1);
    flags = match[1].match(new RegExp(flag_pattern, "g"))
    for (var i = 0; i < flags.length; ++i) {
      if (/^[A-Z]/.test(flags[i][1])) {
          ret[1] = flags[i].substring(1);
          continue;
      }
      switch (flags[i]) {
        case "+se":
          ret[1] = ret[1] == 5 ? 7 : 4;
          break;
        case "+s":
          ret[1] = ret[1] == 5 ? 6 : 3;
          break;
        case "-f":
          // ret[1] = ret[1] == 3 ? 6 : 5;
          switch (ret[1]) {
              case 3:
                ret[1] = 6;
                break;
              case 4:
                ret[1] = 7;
                break;
              default:
                ret[1] = 5;
          }
          break;
        case "+exp":
        case "-std":
          ret[2] = "exp";
          break;
        case "-exp":
        case "+std":
          ret[2] = "std";
          break;
        case "+beta":
          ret[2] = "beta";
          break;
        case "+cbm":
          ret[2] = "cbm";
          break;
        case "+ckt":
          ret[2] = "ckt";
          break;
        case "+morpho":
          ret[2] = "morpho";
          break;
      }
    }
  }
  return ret;
}

function run_camxes(input, mode, engine) {
	var result;
	var syntax_error = false;
	result = camxes_pre.preprocessing(input);
	try {
    switch (engine) {
          case "std":
            result = camxes.parse(result);
            break;
          case "exp":
            result = camxes_exp.parse(result);
            break;
          case "beta":
            result = camxes_beta.parse(result);
            break;
          case "cbm":
            result = camxes_cbm.parse(result);
            break;
          case "ckt":
            result = camxes_ckt.parse(result);
            break;
          case "morpho":
            result = camxes_morpho.parse(result);
            break;
          default:
            throw "Unrecognized parser";
        }
	} catch (e) {
        var location_info = ' Location: [' + e.location.start.offset + ', ' + e.location.end.offset + ']';
        location_info += ' …' + input.substring(e.location.start.offset, e.location.start.offset + 12) + '…';
		result = e.toString() + location_info;
		syntax_error = true;
	}
	if (!syntax_error) {
		//result = JSON.stringify(result, undefined, 2);
		result = camxes_post.postprocessing(result, mode);
	}
	return result;
}
