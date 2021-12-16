import 'dart:html';
import 'dart:collection';

class Graph {
  int mV = -1;
  int mE = -1;
  List<List<int>> mAdj = [];

  Graph(this.mV) {
    mE = 0;
    mAdj = List.generate(mV, (i) => []);
    for (int v = 0; v < mV; v++) {
      mAdj[v] = [];
    }
  }

  int degree(int v) {
    int d = 0;
    var w = adj(v).iterator;
    while (w.moveNext()) {
      d++;
    }
    return d;
  }

  List<int> adj(int v) {
    return mAdj[v];
  }

  void addEdge(int v, int w) {
    mAdj[v].add(w);
    mAdj[w].add(v);
    mE++;
  }

  void printGraph() {
    String str = "<div>Number of vertices : ${mV.toStringAsFixed(0)}</div><br>";
    str += "<div>Number of edges : ${mE.toStringAsFixed(0)} </div><br>";
    print('Number of edges : ${mE.toStringAsFixed(0)}');

    for (int i = 0; i < mAdj.length; i++) {
      str += "<div>${i.toStringAsFixed(0)} ->  ";
      for (int v in mAdj[i]) {
        str += "${v.toStringAsFixed(0)}, ";
      }
      str = str.substring(0, str.length - 2);
      str += "</div>";
    }
    Element? el = document.querySelector('#graph');
    if(el != null) {
      el.setInnerHtml(str);
    }
  }
}

class BreadthFirstPaths {
  List<bool> mMarked = [];
  List<int> mEdgeTo = [];
  int mSource;

  BreadthFirstPaths(Graph g, this.mSource) {
    mMarked = List<bool>.filled(g.mV, false);
    mEdgeTo = List<int>.filled(g.mV, 0);
    bfs(g, mSource);
  }

  void bfs(Graph g, int s) {
    Queue<int> queue = Queue<int>();
    mMarked[s] = true;
    queue.add(s);
    while (queue.isNotEmpty) {
      int v = queue.removeFirst();
      for (int w in g.adj(v)) {
        //if (w != null) {
          if (!mMarked[w]) {
            mEdgeTo[w] = v;
            mMarked[w] = true;
            queue.add(w);
          }
        //}
      }
    }
  }

  bool hasPathTo(int v) {
    return mMarked[v];
  }

  List<int> pathTo(int v) {
    //if (!hasPathTo(v)) return null;
    List<int> path = [];
    for (int x = v; x != mSource; x = mEdgeTo[x]) {
      path.add(x);
    }
    path.add(mSource);
    return path;
  }
}

class Cage {
  int mnIdx = -1;
  int mCenterX = -1;
  int mCenterY = -1;

  bool mWallN = true;
  bool mWallS = true;
  bool mWallE = true;
  bool mWallW = true;
}

class Labyrinth {
  late Graph mG;
  static final mX = 300;
  static final mY = 300;

  int mRows = 5;
  int mCols = 5;

  int mCageWidth = -1;
  int mCageHeight = -1;

  List<Cage> mCages = [];
  late CanvasRenderingContext2D mCtx;

  Labyrinth() {
    CanvasElement canvas = querySelector("#canvas") as CanvasElement;
    mCtx = canvas.getContext('2d') as CanvasRenderingContext2D;
    
    //set up the graph
    mG = Graph(mRows * mCols);
    mG.addEdge(0, 5);
    mG.addEdge(1, 2);
    mG.addEdge(2, 3);
    mG.addEdge(3, 4);
    mG.addEdge(4, 9);

    mG.addEdge(5, 6);
    mG.addEdge(6, 1);
    mG.addEdge(7, 8);
    mG.addEdge(7, 12);
    mG.addEdge(8, 13);
    mG.addEdge(9, 14);

    mG.addEdge(10, 11);
    mG.addEdge(10, 15);
    mG.addEdge(11, 12);
    mG.addEdge(13, 18);
    mG.addEdge(14, 19);

    mG.addEdge(15, 16);
    mG.addEdge(15, 20);
    mG.addEdge(16, 21);
    mG.addEdge(18, 19);

    mG.addEdge(21, 22);
    mG.addEdge(22, 23);
    mG.addEdge(23, 24);

    mCages = [];
    mCageWidth = mX ~/ mRows;
    mCageHeight = mY ~/ mCols;

    InputElement from = querySelector("#from") as InputElement;
    InputElement to = document.querySelector("#to") as InputElement;
    InputElement evalButton = document.querySelector("#eval") as InputElement;
    
    evalButton.onClick.listen((e) {
        int nFrom = int.parse(from.value!);
        int nTo = int.parse(to.value!);
        showLabyrinth(nFrom, nTo);
    });

    showLabyrinth(0, 24);
  }

  void showLabyrinth(int nFrom, int nTo) {
    drawMainRect();

    int cages = mRows * mCols;
    for (int i = 0; i < cages; i++) {
      Cage c = Cage();
      c.mnIdx = i;
      int x = 0 + (mCageWidth * (i % mCols));
      int y = 0 + (mCageHeight * (i ~/ mRows));
      c.mCenterX = x + (mCageWidth ~/ 2);
      c.mCenterY = y + (mCageHeight ~/ 2);
      setCageWalls(c);
      mCages.add(c);
      drawCage(c, x, y);
      drawCageNr(c, i);
    }

    BreadthFirstPaths bfP = BreadthFirstPaths(mG, nFrom);

    if (bfP.hasPathTo(nTo)) {
      List<int> pathBFS = bfP.pathTo(nTo);

      //draw start finish markers
      int u = pathBFS[0];
      Cage cFinish = mCages[u];
      drawText(cFinish.mCenterX + 3, cFinish.mCenterY - 23, "F");

      int v = pathBFS[pathBFS.length - 1];
      Cage cStart = mCages[v];
      drawText(cStart.mCenterX - 23, cStart.mCenterY - 23, "S");

      //draw the path
      String strPath =
          "Path from ${nFrom.toString()} to ${nTo.toString()} = ${pathBFS[pathBFS.length - 1].toString()}";
      for (int i = pathBFS.length - 1; i > 0; i--) {
        int j = pathBFS[i];
        int k = pathBFS[i - 1];
        drawPath(j, k);
        strPath += " - ${k.toString()}";
        //document.querySelector('#path').setInnerHtml(strPath);
        Element? path = document.querySelector('#path');
        if(path != null){
          path.setInnerHtml(strPath);
        }
      }
    } else {
      String strPath =
          "No path from vertex ${nFrom.toString()} to vertex ${nTo.toString()}";
      Element? path = document.querySelector('#path');
      if(path != null){
        path.setInnerHtml(strPath);
      }
    }
  }

  void drawText(int x, int y, String s) {
    mCtx.fillStyle = '#00f';
    mCtx.font = '20px sans-serif';
    mCtx.textBaseline = 'top';
    mCtx.fillText(s, x, y);
  }

  void drawCageNr(Cage c, int i) {
    String s = i.toString();
    mCtx.fillStyle = '#777777';
    mCtx.font = '10px sans-serif';
    mCtx.textBaseline = 'top';
    int x = c.mCenterX + 3;
    int y = c.mCenterY + 3;
    mCtx.fillText(s, x, y);
  }

  void setCageWalls(Cage c) {
    int v = c.mnIdx;
    for (int i in mG.adj(v)) {
      if (i < v) {
        if (i == (v - 1)) {
          c.mWallW = false;
        } else {
          c.mWallN = false;
        }
      }
      if (i > v) {
        if (i == (v + 1)) {
          c.mWallE = false;
        } else {
          c.mWallS = false;
        }
      }
    }
  }

  void drawMainRect() {
    mCtx.clearRect(0, 0, mX, mY);
    mCtx.strokeStyle = '#000';
    mCtx.lineWidth = 4;
    mCtx.beginPath();

    mCtx.moveTo(2, 2);
    mCtx.lineTo(mX - 2, 2);
    mCtx.lineTo(mX - 2, mY - 2);
    mCtx.lineTo(2, mY - 2);
    mCtx.lineTo(2, 2);
    mCtx.stroke();
    mCtx.closePath();
  }

  void drawCage(Cage c, int x, int y) {
    mCtx.strokeStyle = '#000';
    mCtx.lineWidth = 4;
    mCtx.beginPath();

    mCtx.moveTo(x, y);

    if (c.mWallN) {
      mCtx.lineTo(x + mCageWidth, y);
    } else {
      mCtx.moveTo(x + mCageWidth, y);
    }

    if (c.mWallE) {
      mCtx.lineTo(x + mCageWidth, y + mCageHeight);
    } else {
      mCtx.moveTo(x + mCageWidth, y + mCageHeight);
    }

    if (c.mWallS) {
      mCtx.lineTo(x, y + mCageHeight);
    } else {
      mCtx.moveTo(x, y + mCageHeight);
    }

    if (c.mWallW) {
      mCtx.lineTo(x, y);
    } else {
      mCtx.moveTo(x, y);
    }

    mCtx.stroke();
    mCtx.closePath();
  }

  void drawPath(int i, int j) {
    Cage c1 = mCages[i];
    Cage c2 = mCages[j];

    mCtx.strokeStyle = '#f00';
    mCtx.lineWidth = 1;
    mCtx.beginPath();

    mCtx.moveTo(c1.mCenterX, c1.mCenterY);
    mCtx.lineTo(c2.mCenterX, c2.mCenterY);

    mCtx.stroke();
    mCtx.closePath();
  }
}

void main() {
  Labyrinth();
}