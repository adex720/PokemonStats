import 'dart:convert';
import 'dart:core';
import 'dart:html';
import 'dart:math';

main() {
  querySelector('#search-button').onClick.listen((event) async {
    loadCurrentPokemon();
  });

  loadData();
}

loadData() async {
  loadColors();
  await registerPokemonNames();
  loadPokemon('1');
}

loadCurrentPokemon() async {
  InputElement inputElement = querySelector('#search-field');
  if (!isPokemon(inputElement.value)) return;
  await loadPokemon(inputElement.value);
}

loadPokemon(pokemon) async {
  if (!isPokemon(pokemon)) return;

  var url = 'https://pokeapi.co/api/v2/pokemon/' + pokemon;
  var json = await requestJson(url);

  var name = json['forms'][0]['name'];
  var id = await getPokedexNumber(json, name);
  var statsJson = json['stats'];
  var stats = getStatValues(statsJson);
  var typesJson = json['types'];

  switchName(name);
  switchId(id);
  setStats(stats);
  updateTypes(typesJson);
}

requestJson(url) async {
  var response = await HttpRequest.getString(url);
  return jsonDecode(response);
}

var names;

registerPokemonNames() async {
  names = await loadPokemonNames();

  InputElement inputElement = querySelector('#search-field');
  autocomplete(inputElement, names);
}

isPokemon(pokemon) {
  if (pokemon == '') return false;
  var first = pokemon.codeUnitAt(0);
  if (isNumber(first)) {
    try {
      var i = int.parse(pokemon);
      return i <= names.length && i >= 1;
    } catch (e) {
      return names.contains(pokemon.toLowerCase());
    }
  }
  return names.contains(pokemon.toLowerCase());
}

autocomplete(input, options) {
  var currentChoiceId = -1;

  input.onKeyUp.listen((event) {
    if (event.keyCode >= 37 && event.keyCode <= 40) {
      return false;
    }

    closeAllLists();

    var value = input.value;
    if (!shouldShowOptions(value)) return false;
    currentChoiceId = -1;
    Element elementList = createElementList(input);

    // amount of letters typed on input element
    var valueLength = value.length;
    var unequalFound = 0;
    for (var i = 0; i < options.length; i++) {
      if (addOptionIfMatch(options[i], input, value, valueLength, elementList))
        unequalFound++;
    }

    if (unequalFound == 0) closeAllLists();
  });

  input.onKeyDown.listen((event) {
    currentChoiceId = onInputKey(event, currentChoiceId);
  });

  document.onClick.listen((e) {
    closeAllListsForElement(e.target, input);
  });
}

shouldShowOptions(text) {
  if (text == '') return false;
  var first = text.codeUnitAt(0);
  return !isNumber(first);
}

isNumber(letterId) {
  return letterId >= 48 && letterId <= 57;
}

addActive(elements, currentChoiceId) {
  removeActive(elements);
  if (currentChoiceId >= elements.length) currentChoiceId = 0;
  if (currentChoiceId < 0) currentChoiceId = (elements.length - 1);
  elements[currentChoiceId].classes.add('autocomplete-active');
  return currentChoiceId;
}

removeActive(elements) {
  for (var i = 0; i < elements.length; i++) {
    elements[i].classes.remove('autocomplete-active');
  }
}

closeAllLists() {
  var items = querySelectorAll('.autocomplete-items');
  for (var i = 0; i < items.length; i++) {
    items[i].remove();
  }
}

closeAllListsForElement(element, inputElement) {
  var items = querySelectorAll('.autocomplete-items');
  for (var i = 0; i < items.length; i++) {
    if (element != items[i] && element != inputElement) {
      items[i].remove();
    }
  }
}

createElementList(inputElement) {
  var elementList = Element.div();
  elementList.id = 'autocomplete-list';
  elementList.className = 'autocomplete-items';
  inputElement.parentNode.nodes.add(elementList);
  return elementList;
}

addOptionIfMatch(option, input, value, valueLength, elementList) {
  // amount of letters on current option
  var optionLength = option.length;
  if (optionLength < valueLength) return false;

  // start of current option, containing same amount of letters as currently typed on input element
  var optionStart = option.substring(0, valueLength);
  if (optionStart.toUpperCase() != value.toUpperCase()) return false;

  var optionEnd = option.substring(valueLength, option.length);
  createOptionElement(input, elementList, option, optionStart, optionEnd);

  return optionLength != valueLength;
}

createOptionElement(inputElement, elementList, option, optionStart, optionEnd) {
  var optionElement = Element.div();
  optionElement.innerHtml = '<strong>' + optionStart + '</strong>';
  optionElement.innerHtml += optionEnd;
  optionElement.innerHtml += '<input type="hidden" value="' + option + '">';
  optionElement.onClick.listen((e) {
    inputElement.value = option;
    closeAllLists();
    loadCurrentPokemon();
  });
  elementList.nodes.add(optionElement);
}

onInputKey(event, currentChoiceId) {
  var list = querySelector('#autocomplete-list');

  if (event.keyCode == 40) {
    // arrow down
    currentChoiceId++;
    if (list.hasChildNodes()) {
      currentChoiceId = addActive(list.nodes, currentChoiceId);
    }
  } else if (event.keyCode == 38) {
    // arrow up
    currentChoiceId--;
    if (list.hasChildNodes()) {
      currentChoiceId = addActive(list.nodes, currentChoiceId);
    }
  } else if (event.keyCode == 13) {
    // enter
    onInputEnter(event, list, currentChoiceId);
  }

  return currentChoiceId;
}

onInputEnter(event, list, currentChoiceId) {
  event.preventDefault();
  if (currentChoiceId > -1) {
    if (list.hasChildNodes()) {
      runClick(list.nodes[currentChoiceId]);
    }
  } else
    loadCurrentPokemon();
}

runClick(target) {
  MouseEvent clickEvent = new MouseEvent('click', relatedTarget: target);
  target.dispatchEvent(clickEvent);
}

loadPokemonNames() async {
  var url = 'https://pokeapi.co/api/v2/pokemon?offset=0&limit=2000';
  var json = await requestJson(url);

  var pokemonCount = json['count'];
  var pokemonJson = json['results'];
  var pokemonNames = [];
  pokemonNames.length = pokemonCount;

  for (var i = 0; i < pokemonCount; i++) {
    pokemonNames[i] = pokemonJson[i]['name'];
  }
  return pokemonNames;
}

getStatValues(json) {
  var stats = [];
  stats.length = 6;
  for (var i = 0; i < 6; i++) {
    stats[i] = json[i]['base_stat'];
  }
  return stats;
}

getSpeedMod(stats) {
  var speedStat = stats[5];
  return 1 + ((speedStat - 75) * 0.002);
}

getAttack(stats, speedMod) {
  var physical = stats[1];
  var special = stats[3];

  var higher, lower;
  if (physical >= special) {
    higher = physical;
    lower = special;
  } else {
    higher = special;
    lower = physical;
  }

  var lowerMultiplied = 0.125 * lower;
  var higherMultiplied = 0.875 * higher;
  var total = 2 * (lowerMultiplied + higherMultiplied);
  var scaled = total.round();
  return (scaled * speedMod).round();
}

getDefence(stats, speedMod) {
  var physical = stats[2];
  var special = stats[4];

  var higher, lower;
  if (physical >= special) {
    higher = physical;
    lower = special;
  } else {
    higher = special;
    lower = physical;
  }

  var lowerMultiplied = 0.375 * lower;
  var higherMultiplied = 0.625 * higher;
  var total = 2 * (lowerMultiplied + higherMultiplied);
  var scaled = total.round();
  return (scaled * speedMod).round();
}

getStamina(stats) {
  var staminaStat = stats[0];
  return (1.75 * staminaStat).floor() + 50;
}

var cpm = 0.7903;
var cpmSquared = cpm * cpm;

getCp(attack, defence, stamina) {
  // Calculating cp for 100% species
  attack += 15;
  defence += 15;
  stamina += 15;

  var defenceSqrt = sqrt(defence);
  var staminaSqrt = sqrt(stamina);

  var statSum = attack * defenceSqrt * staminaSqrt * cpmSquared;
  //if (statSum <= 100) return 10; This isn't the case on level 40 pokemons

  return (statSum * 0.1).floor();
}

getPokedexNumber(json, String name) async {
  var id = json['id'];
  if (id < 1000) return id;

  if (name == null) return -1;

  var nameWithoutForm = name.split('-')[0];
  if (nameWithoutForm == 'pumpkaboo') nameWithoutForm = 'pumpkaboo-average';

  var url = 'https://pokeapi.co/api/v2/pokemon/' + nameWithoutForm;
  json = await requestJson(url);
  return await getPokedexNumber(json, null);
}

switchName(name) {
  var firstLetter = name.substring(0, 1).toUpperCase();
  var otherLetters = name.substring(1, name.length);
  var formattedName = firstLetter + otherLetters;
  querySelector('#name').text = formattedName;
}

switchId(id) {
  querySelector('#number').text = id.toString();
}

updatePokemonColor(color) {
  querySelector('#name').style.backgroundColor = color;
  querySelector('#number').style.backgroundColor = color;
}

updateTypes(typesJson) {
  var type1 = typesJson[0]['type']['name'];
  switchType(type1, 1);
  if (typesJson.length > 1) {
    var type2 = typesJson[1]['type']['name'];
    switchType(type2, 2);
  } else {
    switchType(null, 2);
  }
}

switchType(type, typeId) {
  var elementName = '#type' + typeId.toString();
  if (type == null) {
    updateTypeElement(elementName, '', '#FFFFFF', '#FFFFFF');
    return;
  }

  var backgroundColor = getTypeColor(type);
  var textColor = getTypeTextColor(backgroundColor);
  updateTypeElement(elementName, type, textColor, backgroundColor);
}

updateTypeElement(elementName, type, textColor, backgroundColor) {
  var element = querySelector(elementName);
  element.text = type;
  element.style.backgroundColor = backgroundColor;
  element.style.color = textColor;
}

var colors;

loadColors() {
  colors = new Map();
  colors['normal'] = '#A8A77A';
  colors['fire'] = '#EE8130';
  colors['water'] = '#6390F0';
  colors['electric'] = '#F7D02C';
  colors['grass'] = '#7AC74C';
  colors['ice'] = '#96D9D6';
  colors['fighting'] = '#C22E28';
  colors['poison'] = '#A33EA1';
  colors['ground'] = '#E2BF65';
  colors['flying'] = '#A98FF3';
  colors['psychic'] = '#F95587';
  colors['bug'] = '#A6B91A';
  colors['rock'] = '#B6A136';
  colors['ghost'] = '#735797';
  colors['dragon'] = '#6F35FC';
  colors['dark'] = '#705746';
  colors['steel'] = '#B7B7CE';
  colors['fairy'] = '#D685AD';
}

getTypeColor(type) {
  return colors[type];
}

getTypeTextColor(backgroundColor) {
  var i = int.parse(backgroundColor.substring(1, 7), radix: 16);
  var red = i >> 16;
  var green = (i >> 8) & 0xFF;
  var blue = i & 0xFF;
  var sum = red + green + blue;

  if (sum > 0x17F) return '#000000';
  return '#FFFFFF';
}

setStats(stats) {
  var speedMod = getSpeedMod(stats);
  var attack = getAttack(stats, speedMod);
  var defence = getDefence(stats, speedMod);
  var stamina = getStamina(stats);
  var cp = getCp(attack, defence, stamina);

  querySelector('#attack-value').text = attack.toString();
  querySelector('#defence-value').text = defence.toString();
  querySelector('#stamina-value').text = stamina.toString();
  querySelector('#cp-value').text = cp.toString();
}
