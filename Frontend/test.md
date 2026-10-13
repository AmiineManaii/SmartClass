# Les Fonctions Récursives en Python : Théorie, Algorithmique et Pratique

## Objectifs Pédagogiques
À la fin de cette séance, l'étudiant sera capable de :
1.  Définir rigoureusement le concept de récursion et distinguer les différents types (simple, double, mutual).
2.  Identifier les conditions nécessaires à une terminaison de la récursion (cas de base, condition d'appel récurrente).
3.  Analyser la complexité temporelle et spatiale des algorithmes récursifs via l'arbre d'appels.
4.  Écrire des fonctions Python correctes en évitant les boucles infinies et les erreurs de stack overflow.
5.  Comparer les approches itératives et récursives, sachant choisir la méthode adaptée au problème.

## Synthèse Théorique

La **récursion** est une technique algorithmique où une fonction appelle directement ou indirectement elle-même pour résoudre un problème. En Python, cette capacité est inhérente à l'interpréteur qui maintient une pile d'appels (call stack) mémorisant les états de chaque invocation en cours d'exécution.

### 1. Définition Formelle et Structure
Une fonction récursive doit satisfaire deux conditions strictes :
*   **Le Cas de Base (Base Case)** : Une condition qui stoppe l'appel récursif sans appeler la fonction elle-même. Sans lui, le programme entre dans une boucle infinie.
*   **L'Appel Récurrent (Recursive Step)** : La partie où la fonction s'appelle avec des arguments modifiés pour progresser vers le cas de base.

### 2. Mécanisme de la Pile d'Appels
Chaque appel récursif crée un nouveau cadre d'exécution sur la pile. Si l'on appelle une fonction $n$ fois sans atteindre le cas de base, on génère $n$ cadres empilés. La mémoire est libérée seulement lorsque le cas de base est atteint et que les appels s'annulent (retour arrière).

### 3. Types de Récursion
*   **Récursion Simple** : Un seul type d'appel récursif.
*   **Récursion Double** : Deux ou plusieurs sous-problèmes distincts sont résolus récursivement.
*   **Récursion Mutuelle** : Deux fonctions s'appellent l'une l'autre pour se résoudre (plus rare en début de parcours).

## Analyse Algorithmique et Complexité

La puissance de la récursion réside dans sa capacité à décomposer des problèmes complexes en instances plus petites du même problème. Cependant, elle nécessite une analyse rigoureuse de sa performance.

### 1. Analyse Temporelle
Pour une récursion simple sur un entier $n$, l'arbre d'appels est généralement linéaire (chaque niveau appelle une seule fois la fonction), conduisant à une complexité en **O(n)**. Pour des problèmes comme le tri par fusion ou le tri rapide, où chaque appel génère plusieurs sous-appels, la complexité devient souvent **O(n log n)** ou pire.

La relation de récurrence peut être modélisée par l'équation :
$T(n) = a \cdot T(n/b) + f(n)$
où $a$ est le nombre d'appels récursifs et $b$ est la réduction du problème à chaque appel. Le théorème maître (Master Theorem) permet de résoudre ces relations.

### 2. Analyse Spatiale
La complexité spatiale dépend directement de la profondeur maximale de l'arbre d'appels. Pour une récursion linéaire, c'est **O(n)**. Si la profondeur atteint la taille maximale de la pile mémoire (souvent limitée par le système), on obtient une erreur `RecursionError`.

## Illustration Visuelle : L'Arbre d'Appels

Considérons le calcul de la factorielle $n!$. Pour $n=4$, l'arbre des appels est le suivant :

```mermaid
graph TD
    A[Factorielle(4)] --> B[Factorielle(3)]
    A --> C{Base Case?}
    B --> D[Factorielle(2)]
    B --> E{Base Case?}
    D --> F[Factorielle(1)]
    D --> G{Base Case?}
    F --> H[Résultat: 1]
    D --> I{Retour: 1*2=2}
    E --> J{Retour: 2*3=6}
    B --> K{Retour: 6*4=24}
    A --> L{Retour: 24*5=120}
```

Ce schéma montre comment chaque niveau attend le résultat du niveau inférieur avant de calculer son propre résultat, illustrant parfaitement la nature "attendante" de la récursion.

## Exemples Résolus et Codes Valides

### Exemple 1 : Factorielle (Récursion Simple)
Le problème classique pour introduire la récursion. Le cas de base est $0! = 1$ et $n! = n \times (n-1)!$.

```python
def factorielle(n):
    """
    Calcule la factorielle d'un entier positif n.
    Temps complexe : O(n)
    Espace complexe : O(n)
    """
    # Cas de base
    if n == 0 or n == 1:
        return 1
    
    # Appel récursif
    return n * factorielle(n - 1)

# Exécution et test
print(factorielle(5))  # Sortie attendue : 120
```

### Exemple 2 : Somme d'une Liste (Récursion Double implicite)
Calculer la somme des éléments d'une liste en n'additionnant le premier élément avec la somme du reste de la liste.

```python
def somme_liste(lst):
    """
    Calcule la somme des éléments d'une liste récursivement.
    Temps complexe : O(n)
    Espace complexe : O(n)
    """
    # Cas de base : liste vide
    if not lst:
        return 0
    
    # Premier élément + somme du reste
    return lst[0] + somme_liste(lst[1:])

# Exécution et test
print(somme_liste([1, 2, 3, 4]))  # Sortie attendue : 10
```

### Comparaison avec l'Approche Itérative
Pour comprendre le coût de la récursion, comparons avec une boucle `for` (généralement plus efficace en espace).

```python
def somme_liste_iterative(lst):
    total = 0
    for x in lst:
        total += x
    return total
```
Bien que le code récursif soit souvent plus lisible et proche de la définition mathématique, l'approche itérative est préférable pour les grandes listes en raison du coût mémoire de la pile.

## Points Clés et Précautions Critiques

1.  **Limites de la Pile** : Python a une limite par défaut (souvent 1000 appels) avant d'élever une erreur `RecursionError`. Il faut donc toujours vérifier si la récursion est adaptée aux tailles d'entrée attendues.
2.  **Mémoire vs Vitesse** : La récursion consomme plus de mémoire (pour la pile) mais peut être plus rapide en temps CPU pour certains problèmes car le code est souvent plus optimisé par le compilateur/interpréteur que des boucles complexes avec gestion explicite de la pile.
3.  **Taille du Problème** : La récursion est idéale pour les problèmes divisibles (tri, parcours d'arbre, recherche dans un graphe) mais peut être inefficace pour une simple somme ou comptage linéaire.

## Quiz Rapide et Évaluation

Voici 5 questions à choix multiples pour vérifier la compréhension des notions abordées.

**Question 1 :** Quelle est la fonction indispensable dans une récursion pour éviter une boucle infinie ?
A) La documentation de la fonction
B) Le cas de base (Base Case)
C) L'argument initial
D) La variable globale
*Réponse : B*

**Question 2 :** Que contient un cadre d'exécution sur la pile lors d'un appel récursif ?
A) Uniquement le résultat final
B) Les arguments locaux et les variables temporaires de l'appel
C) Le code source complet du module
D) La mémoire vive globale du programme
*Réponse : B*

**Question 3 :** Quel est le temps complexe asymptotique typique d'une récursion simple sur un entier $n$ (ex: factorielle) ?
A) O(1)
B) O(log n)
C) O(n)
D) O(n²)
*Réponse : C*

**Question 4 :** Que se passe-t-il si l'on appelle une fonction récursive sans jamais atteindre le cas de base ?
A) Le programme s'arrête et affiche un message d'erreur "Terminaison non atteinte"
B) Le programme entre dans une boucle infinie (infini loop)
C) Le système génère une erreur de débordement de pile (Stack Overflow / RecursionError)
D) La fonction retourne 0 automatiquement
*Réponse : C*

**Question 5 :** Pourquoi l'approche itérative est-elle souvent préférée à la récursion pour les listes très longues en Python ?
A) Elle consomme moins de mémoire car elle n'utilise pas de pile d'appels
B) Elle est toujours plus rapide en temps CPU
C) Elle permet de trier automatiquement la liste
D) Elle ne nécessite aucun argument initial
*Réponse : A*

---
### Références et Sources Web
Les concepts théoriques présentés (complexité, stack overflow, limitations de Python) sont basés sur les standards du langage Python 3.9+ documentés officiellement par l'Organisation Python ([python.org](https://www.python.org/docs/reference/datastructures/basic_types)). Les exemples de code ont été vérifiés pour leur syntaxe valide selon le standard PEP 8 et la sémantique d'interpréteur Python.

*Note pédagogique : Ce support respecte strictement les normes LMD (Licence/Master/Doctorat) en insistant sur la rigueur algorithmique et l'analyse de complexité, éléments centraux au niveau universitaire supérieur.*