function camxes_preprocessing(input) {
	if (!(typeof input.valueOf() === 'string'))
		return "ERROR: Wrong input type.";
	input = input.replace(/’/gm,"'");
	input = input.replace(/·/gm,".");
    input = input.replace(/\u00AD/gm,"");
	input = input.replace(/([0-9])\.([0-9])/gm,"$1 pi $2");
	input = input.replace(/0/gm,"no");
	input = input.replace(/1/gm,"pa");
	input = input.replace(/2/gm,"re");
	input = input.replace(/3/gm,"ci");
	input = input.replace(/4/gm,"vo");
	input = input.replace(/5/gm,"mu");
	input = input.replace(/6/gm,"xa");
	input = input.replace(/7/gm,"ze");
	input = input.replace(/8/gm,"bi");
	input = input.replace(/9/gm,"so");
	// --- //
	input = input.replace(/[áàâä]/g,"A");
	input = input.replace(/[éèêë]/g,"E");
	input = input.replace(/[íìîïĭị]/g,"I");
	input = input.replace(/[óòôö]/g,"O");
	input = input.replace(/[úùûüŭụw]/g,"U");
	input = input.replace(/[ýỳŷÿ]/g,"Y");
	// --- //
	input = input.replace(/sh/igm,"c");
	input = input.replace(/zh/igm,"j");
	input = input.replace(/ch/igm,"tc");
	input = input.replace(/kh/igm,"x");
	// --- //
	input = input.replace(/ı/igm,"i");
	input = input.replace(/ʃ/igm,"c");
	input = input.replace(/ʒ/igm,"j");
	input = input.replace(/ɛ/gm,"e");
	input = input.replace(/[Ɛɛ́ɛ̀ɛ̂ɛ̈]/gm,"E");
        input = input.replace(/ə/igm,"y");
        input = input.replace(/ŋ/igm,"ng");
	// --- //
	input = input.replace(/([cfkpstx])([bdgjvz])/igm,"$1y$2");
	input = input.replace(/([bdgjvz])([cfkpstx])/igm,"$1y$2");
	// --- //
	var a = {"Ё":"IO","Й":"I","Ц":"TS","У":"U","К":"K","Е":"E","Н":"N","Г":"G","Ш":"C","Щ":"C","З":"Z","Х":"X","Ъ":"Y","Ь":"'","ё":"io","й":"i","ц":"ts","у":"u","к":"k","е":"e","н":"n","г":"g","ш":"c","щ":"c","з":"z","х":"x","ъ":"y","ь":"'","Ф":"F","Ы":"Y","В":"V","А":"a","П":"P","Р":"R","О":"O","Л":"L","Д":"D","Ж":"J","Э":"E","ф":"f","ы":"y","в":"v","а":"a","п":"p","р":"r","о":"o","л":"l","д":"d","ж":"j","э":"e","Я":"IA","Ч":"TC","С":"S","М":"M","И":"I","Т":"T","Б":"B","Ю":"IU","я":"ia","ч":"tc","с":"s","м":"m","и":"i","т":"t","б":"b","ю":"iu"};
	function transliterate(word){
  	return word.split('').map(function (char) { 
    return a[char] || char; 
  	}).join("");
	}
	input = transliterate(input);
	// --- //
	input = input.replace(/\(|\)|«|»|—|:/gm,"");
	return input;
}

if (typeof module !== 'undefined')
    module.exports.preprocessing = camxes_preprocessing;

