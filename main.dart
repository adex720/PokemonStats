import 'dart:convert';
import 'dart:core';
import 'dart:html';
import 'dart:math';

main() {
  querySelector('#search-button').onClick.listen((event) async {
    loadCurrentPokemon();
  });

  querySelector('#search-button').onKeyPress.listen((event) {
    print(event.keyCode);
  });

  loadData();
}

loadData() async {
  registerPokemonNames();
  loadPokemon('1');
}

loadCurrentPokemon() async {
  InputElement inputElement = querySelector('#search-field');
  await loadPokemon(inputElement.value);
}

loadPokemon(pokemon) async {
  var url = 'https://pokeapi.co/api/v2/pokemon/' + pokemon;
  var json = await requestJson(url);

  var name = json['forms'][0]['name'];
  var statsJson = json['stats'];
  var stats = getStatValues(statsJson);

  switchName(name);
  setStats(stats);
}

requestJson(url) async {
  var response = await HttpRequest.getString(url);
  return jsonDecode(response);
}

registerPokemonNames() async {
  var names = await loadPokemonNames();

  InputElement inputElement = querySelector('#search-field');
  autocomplete(inputElement, names);
}

autocomplete(input, options) {
  var currentChoiceId;

  removeActive(elements) {
    for (var i = 0; i < elements.length; i++) {
      elements[i].classes.remove("autocomplete-active");
    }
  }

  addActive(elements) {
    removeActive(elements);
    if (currentChoiceId >= elements.length) currentChoiceId = 0;
    if (currentChoiceId < 0) currentChoiceId = (elements.length - 1);
    elements[currentChoiceId].classes.add("autocomplete-active");
  }

  closeAllLists() {
    var x = querySelectorAll(".autocomplete-items");
    for (var i = 0; i < x.length; i++) {
      x[i].remove();
    }
  }

  closeAllListsForElement(element) {
    var x = querySelectorAll(".autocomplete-items");
    for (var i = 0; i < x.length; i++) {
      if (element != x[i] && element != input) {
        x[i].remove();
      }
    }
  }

  input.onKeyUp.listen((event) {
    if (event.keyCode >= 37 && event.keyCode <= 40) {
      return false;
    }

    closeAllLists();

    var value = input.value;
    if (value == '') return false;
    var first = value.codeUnitAt(0);
    if (first == '0' ||
        first == '1' ||
        first == '2' ||
        first == '3' ||
        first == '4' ||
        first == '5' ||
        first == '6' ||
        first == '7' ||
        first == '8' ||
        first == '9') return false;

    currentChoiceId = -1;

    var a = Element.div();
    a.id = "autocomplete-list";
    a.className = "autocomplete-items";
    input.parentNode.nodes.add(a);

    for (var i = 0; i < options.length; i++) {
      var option = options[i];
      if (option.length >= value.length &&
          option.substring(0, value.length).toUpperCase() ==
              value.toUpperCase()) {
        var b = Element.div();

        b.innerHtml =
            "<strong>" + option.substring(0, value.length) + "</strong>";
        b.innerHtml += option.substring(value.length, option.length);
        b.innerHtml += "<input type='hidden' value='" + option + "'>";
        b.onClick.listen((e) {
          input.value = option;
          closeAllLists();
          loadCurrentPokemon();
        });
        a.nodes.add(b);
      }
    }
  });

  input.onKeyDown.listen((e) {
    var list = querySelector('#autocomplete-list');

    if (e.keyCode == 40) {
      currentChoiceId++;
      if (list.hasChildNodes()) addActive(list.nodes);
    } else if (e.keyCode == 38) {
      currentChoiceId--;
      if (list.hasChildNodes()) addActive(list.nodes);
    } else if (e.keyCode == 13) {
      e.preventDefault();
      if (currentChoiceId > -1) {
        if (list.hasChildNodes()) {
          var target = list.nodes[currentChoiceId];
          MouseEvent event = new MouseEvent('click',
              detail: 0,
              screenX: 0,
              screenY: 0,
              clientX: 0,
              clientY: 0,
              button: 0,
              canBubble: true,
              cancelable: true,
              relatedTarget: target);
          target.dispatchEvent(event);
        }
      } else
        loadCurrentPokemon();
    }
  });

  document.onClick.listen((e) {
    closeAllListsForElement(e.target);
  });
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

switchName(name) {
  querySelector('#name').text = name;
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
