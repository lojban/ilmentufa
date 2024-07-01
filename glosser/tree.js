/**
 * This file contains functions that simplify the parse tree returned by camxes.js.
 *
 * The original parse tree has the following structure:
 * [
 *   "...",   // the type
 *   ...      // children as array elements
 * ]
 * Here, the first element of every array indicates the type of the object parsed, and the
 * next objects are the children of the element.
 *
 * The simplified parse tree has quite another structure:
 * [
 *   {
 *     type: "...",
 *     children: [ ... ],   // only one of children and word
 *     word: "...",
 *     ...: ...             // other optional elements
 *   }
 * ]
 * Here, type gives the type. For non-terminals, children is an array containing the children.
 * For terminals, word contains the actual word parsed. (Of course, one cannot have both
 * children and word.) Furthermore, there can be more elements added to this structure to add
 * additional information as needed.
 */

/**
 * Simplifies the given parse tree. Returns an array.
 */
function simplifyTree(parseTree) {
  if (
    parseTree.length === 2 &&
    isString(parseTree[0]) &&
    isString(parseTree[1])
  ) {
    return [{ type: parseTree[0], word: parseTree[1] }];
  }

  const simplifyFunc = simplifyFunctions[parseTree[0]];

  if (simplifyFunc) {
    return [simplifyFunc(parseTree)];
  }

  return simplifyArrayOfTrees(
    isString(parseTree[0]) ? parseTree.slice(1) : parseTree
  );
}

/**
 * Simplifies an array of trees.
 */
function simplifyArrayOfTrees(trees) {
  return trees.flatMap(simplifyTree);
}

// The simplification functions

const simplifyFunctions = {
  text: (tree) => ({
    type: "text",
    children: simplifyArrayOfTrees(tree.slice(1)),
  }),
  free: (tree) => ({
    type: "free modifier",
    children: simplifyArrayOfTrees(tree.slice(1)),
  }),
  sentence: (tree) => ({
    type: "sentence",
    children: simplifyArrayOfTrees(tree.slice(1)),
  }),
  prenex: (tree) => ({
    type: "prenex",
    children: simplifyArrayOfTrees(tree.slice(1)),
  }),
  bridi_tail: (tree) => ({
    type: "bridi tail",
    children: simplifyArrayOfTrees(tree.slice(1)),
  }),
  selbri: (tree) => ({
    type: "selbri",
    children: simplifyArrayOfTrees(tree.slice(1)),
  }),
  sumti: (tree) => ({
    type: "sumti",
    children: simplifyArrayOfTrees(tree.slice(1)),
  }),
  sumti_6: (tree) => {
    const [firstChild] = tree[1];
    const type = (() => {
      switch (firstChild) {
        case "ZO_clause":
          return "one-word quote";
        case "ZOI_clause":
          return "non-Lojban quote";
        case "LOhU_clause":
          return "ungrammatical quote";
        case "lerfu_string":
          return "letterals";
        case "LU_clause":
          return "grammatical quote";
        case "KOhA_clause":
          return "sumka'i";
        case "LA_clause":
          return "name or name description";
        case "LE_clause":
          return "description";
        case "li_clause":
          return "number";
        default:
          if (Array.isArray(firstChild)) {
            if (firstChild[0] === "LAhE_clause") return "reference sumti";
            if (firstChild[0] === "NAhE_clause") return "negated sumti";
          }
          return "unknown type sumti (bug?)";
      }
    })();

    return {
      type,
      children: simplifyArrayOfTrees(tree.slice(1)),
    };
  },
  relative_clause: (tree) => ({
    type: "relative clause",
    children: simplifyArrayOfTrees(tree.slice(1)),
  }),
};

/**
 * Numbers the placed sumti in the parse tree.
 */
function numberSumti(tree) {
  if (tree.type === "sentence") {
    numberSumtiInSentence(tree);
  }

  if (typeof tree === "object") {
    Object.values(tree).forEach((value) => {
      if (typeof value === "object") {
        numberSumti(value);
      }
    });
  }

  return tree;
}

function numberSumtiInSentence(sentence) {
  const sentenceElements = sentence.children.flatMap((child) =>
    child.type === "bridi tail"
      ? [{ type: "bridi tail start" }, ...child.children]
      : [child]
  );

  let currentSumtiNumber = 1;
  let bridiTailStartSumtiNumber = 1;
  let isNextElementModal = false;
  const sumtiSections = {
    head: [],
    gihek: [[]],
    selbri: [],
    vau: [],
  };
  let headSumtiCount = 0;
  let vauSumtiCount = 0;
  let isHeadBareSumtiEnded = false;
  let isVauBareSumtiEnded = false;
  let lastGihekSumtiNumber = null;
  let lastFAPlaceNumber = null;
  let currentSection = "head";

  sentenceElements.forEach((element) => {
    if (element.type === "bridi tail start") {
      bridiTailStartSumtiNumber = currentSumtiNumber;
    }

    if (element.type === "selbri") {
      lastGihekSumtiNumber = null;
      sumtiSections.selbri.push(
        element.children.map(({ word }) => word).join(" ")
      );
      currentSection = "gihek";
    }

    if (element.type === "GIhA") {
      lastFAPlaceNumber = null;
      sumtiSections.gihek.push([]);
      currentSumtiNumber = bridiTailStartSumtiNumber;
    }

    if (element.type === "FA") {
      lastFAPlaceNumber = null;
      if (currentSection === "head") isHeadBareSumtiEnded = true;
      if (currentSection === "vau") isVauBareSumtiEnded = true;
      currentSumtiNumber = placeTagToPlace(element);
      if (currentSection === "gihek") {
        sumtiSections.gihek[sumtiSections.gihek.length - 1].push(
          placeTagToPlace(element)
        );
      } else {
        sumtiSections[currentSection].push(placeTagToPlace(element));
      }
    }

    if (element.type === "VAU") {
      lastFAPlaceNumber = null;
      currentSection = "vau";
    }

    if (
      [
        "BAI",
        "FAhA",
        "PU",
        "CAhA",
        "CUhE",
        "KI",
        "ZI",
        "ZEhA",
        "VA",
        "VEhA",
        "VIhA",
        "ROI",
        "TAhE",
        "ZAhO",
      ].includes(element.type)
    ) {
      isNextElementModal = true;
    }

    if (element.type === "sumti") {
      if (isNextElementModal) {
        element.type = "modal sumti";
        isNextElementModal = false;
      } else {
        element.type = "sumti x";
        if (currentSection === "gihek") {
          const lastSumtiInSection =
            sumtiSections.gihek[sumtiSections.gihek.length - 1].at(-1);
          if (lastSumtiInSection !== undefined) {
            if (lastFAPlaceNumber === null) {
              lastFAPlaceNumber = lastSumtiInSection;
              element.sumtiPlace = lastSumtiInSection;
            } else {
              lastFAPlaceNumber++;
              element.sumtiPlace = lastFAPlaceNumber;
            }
          } else {
            if (lastGihekSumtiNumber === null) {
              lastGihekSumtiNumber = headSumtiCount + 1;
              element.sumtiPlace = lastGihekSumtiNumber;
            } else {
              lastGihekSumtiNumber++;
              element.sumtiPlace = lastGihekSumtiNumber;
            }
          }
        } else if (currentSection == "vau") {
          if (!isVauBareSumtiEnded) {
            vauSumtiCount++;
            element.sumtiPlace = vauSumtiCount;
          } else {
            const lastSumtiInSection = sumtiSections[currentSection].at(-1);
            element.sumtiPlace = lastSumtiInSection;
            if (lastFAPlaceNumber === null) {
              lastFAPlaceNumber = lastSumtiInSection;
              element.sumtiPlace = lastSumtiInSection;
            } else {
              lastFAPlaceNumber++;
              element.sumtiPlace = lastFAPlaceNumber;
            }
          }
        } else {
          //head
          const lastSumtiInSection = sumtiSections[currentSection].at(-1);
          if (!isHeadBareSumtiEnded) {
            headSumtiCount++;
            vauSumtiCount = headSumtiCount;
            element.sumtiPlace = headSumtiCount;
          } else {
            if (lastFAPlaceNumber === null) {
              lastFAPlaceNumber = lastSumtiInSection;
              element.sumtiPlace = lastSumtiInSection;
            } else {
              lastFAPlaceNumber++;
              element.sumtiPlace = lastFAPlaceNumber;
            }
          }
        }

        currentSumtiNumber++;
      }
    }

    if (element.type === "selbri" && currentSumtiNumber === 1) {
      currentSumtiNumber++;
    }
  });
}

const faNumberMap = {
  fa: 1,
  fe: 2,
  fi: 3,
  fo: 4,
  fu: 5,
};

function placeTagToPlace(tag) {
  const placeNumber = faNumberMap[tag.word];
  if (placeNumber) return placeNumber;
  if (tag.word === "fai") {
    return "fai";
    /* Ilmen: Yeah that's an ugly lazy handling of "fai", but a cleaner
     * handling will require more work. */
  }
}
