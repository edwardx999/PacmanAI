# captureAgents.py
# ----------------
# Licensing Information:  You are free to use or extend these projects for
# educational purposes provided that (1) you do not distribute or publish
# solutions, (2) you retain this notice, and (3) you provide clear
# attribution to UC Berkeley, including a link to http://ai.berkeley.edu.
#
# Attribution Information: The Pacman AI projects were developed at UC Berkeley.
# The core projects and autograders were primarily created by John DeNero
# (denero@cs.berkeley.edu) and Dan Klein (klein@cs.berkeley.edu).
# Student side autograding was added by Brad Miller, Nick Hay, and
# Pieter Abbeel (pabbeel@cs.berkeley.edu).


"""
  Interfaces for capture agents and agent factories
"""

from genes import Genes
from game import Agent
import distanceCalculator
from util import nearestPoint
import util
import numpy as np
import random

# Note: the following class is not used, but is kept for backwards
# compatibility with team submissions that try to import it.


class AgentFactory:
    "Generates agents for a side"

    def __init__(self, isRed, **args):
        self.isRed = isRed

    def getAgent(self, index):
        "Returns the agent for the provided index."
        util.raiseNotDefined()


class RandomAgent(Agent):
    """
    A random agent that abides by the rules.
    """

    def __init__(self, index):
        self.index = index

    def getAction(self, state):
        return random.choice(state.getLegalActions(self.index))


class CaptureAgent(Agent):
    """
    A base class for capture agents.  The convenience methods herein handle
    some of the complications of a two-team game.

    Recommended Usage:  Subclass CaptureAgent and override chooseAction.
    """

    #############################
    # Methods to store key info #
    #############################

    def __init__(self, index, timeForComputing=.1):
        """
        Lists several variables you can query:
        self.index = index for this agent
        self.red = true if you're on the red team, false otherwise
        self.agentsOnTeam = a list of agent objects that make up your team
        self.distancer = distance calculator (contest code provides this)
        self.observationHistory = list of GameState objects that correspond
            to the sequential order of states that have occurred so far this game
        self.timeForComputing = an amount of time to give each turn for computing maze distances
            (part of the provided distance calculator)
        """
        # Agent index for querying state
        self.index = index

        # Whether or not you're on the red team
        self.red = None

        # Agent objects controlling you and your teammates
        self.agentsOnTeam = None

        # Maze distance calculator
        self.distancer = None

        # A history of observations
        self.observationHistory = []

        # Time to spend each turn on computing maze distances
        self.timeForComputing = timeForComputing

        # Access to the graphics
        self.display = None

    def registerInitialState(self, gameState):
        """
        This method handles the initial setup of the
        agent to populate useful fields (such as what team
        we're on).

        A distanceCalculator instance caches the maze distances
        between each pair of positions, so your agents can use:
        self.distancer.getDistance(p1, p2)
        """
        self.red = gameState.isOnRedTeam(self.index)
        self.distancer = distanceCalculator.Distancer(gameState.data.layout)

        # comment this out to forgo maze distance computation and use manhattan distances
        self.distancer.getMazeDistances()

        import __main__
        if '_display' in dir(__main__):
            self.display = __main__._display

    def final(self, gameState):
        self.observationHistory = []

    def registerTeam(self, agentsOnTeam):
        """
        Fills the self.agentsOnTeam field with a list of the
        indices of the agents on your team.
        """
        self.agentsOnTeam = agentsOnTeam

    def observationFunction(self, gameState):
        " Changing this won't affect pacclient.py, but will affect capture.py "
        return gameState.makeObservation(self.index)

    def debugDraw(self, cells, color, clear=False):

        if self.display:
            from captureGraphicsDisplay import PacmanGraphics
            if isinstance(self.display, PacmanGraphics):
                if not type(cells) is list:
                    cells = [cells]
                self.display.debugDraw(cells, color, clear)

    def debugClear(self):
        if self.display:
            from captureGraphicsDisplay import PacmanGraphics
            if isinstance(self.display, PacmanGraphics):
                self.display.clearDebug()

    #################
    # Action Choice #
    #################

    def getAction(self, gameState):
        """
        Calls chooseAction on a grid position, but continues on half positions.
        If you subclass CaptureAgent, you shouldn't need to override this method.  It
        takes care of appending the current gameState on to your observation history
        (so you have a record of the game states of the game) and will call your
        choose action method if you're in a state (rather than halfway through your last
        move - this occurs because Pacman agents move half as quickly as ghost agents).

        """
        self.observationHistory.append(gameState)

        myState = gameState.getAgentState(self.index)
        myPos = myState.getPosition()
        if myPos != nearestPoint(myPos):
            # We're halfway from one position to the next
            return gameState.getLegalActions(self.index)[0]
        else:
            return self.chooseAction(gameState)

    def chooseAction(self, gameState):
        """
        Override this method to make a good agent. It should return a legal action within
        the time limit (otherwise a random legal action will be chosen for you).
        """
        util.raiseNotDefined()

    #######################
    # Convenience Methods #
    #######################

    def getFood(self, gameState):
        """
        Returns the food you're meant to eat. This is in the form of a matrix
        where m[x][y]=true if there is food you can eat (based on your team) in that square.
        """
        if self.red:
            return gameState.getBlueFood()
        else:
            return gameState.getRedFood()

    def getFoodYouAreDefending(self, gameState):
        """
        Returns the food you're meant to protect (i.e., that your opponent is
        supposed to eat). This is in the form of a matrix where m[x][y]=true if
        there is food at (x,y) that your opponent can eat.
        """
        if self.red:
            return gameState.getRedFood()
        else:
            return gameState.getBlueFood()

    def getCapsules(self, gameState):
        if self.red:
            return gameState.getBlueCapsules()
        else:
            return gameState.getRedCapsules()

    def getCapsulesYouAreDefending(self, gameState):
        if self.red:
            return gameState.getRedCapsules()
        else:
            return gameState.getBlueCapsules()

    def getOpponents(self, gameState):
        """
        Returns agent indices of your opponents. This is the list of the numbers
        of the agents (e.g., red might be "1,3,5")
        """
        if self.red:
            return gameState.getBlueTeamIndices()
        else:
            return gameState.getRedTeamIndices()

    def getTeam(self, gameState):
        """
        Returns agent indices of your team. This is the list of the numbers
        of the agents (e.g., red might be the list of 1,3,5)
        """
        if self.red:
            return gameState.getRedTeamIndices()
        else:
            return gameState.getBlueTeamIndices()

    def getScore(self, gameState):
        """
        Returns how much you are beating the other team by in the form of a number
        that is the difference between your score and the opponents score.  This number
        is negative if you're losing.
        """
        if self.red:
            return gameState.getScore()
        else:
            return gameState.getScore() * -1

    def getMazeDistance(self, pos1, pos2):
        """
        Returns the distance between two points; These are calculated using the provided
        distancer object.

        If distancer.getMazeDistances() has been called, then maze distances are available.
        Otherwise, this just returns Manhattan distance.
        """
        d = self.distancer.getDistance(pos1, pos2)
        return d

    def getPreviousObservation(self):
        """
        Returns the GameState object corresponding to the last state this agent saw
        (the observed state of the game last time this agent moved - this may not include
        all of your opponent's agent locations exactly).
        """
        if len(self.observationHistory) == 1:
            return None
        else:
            return self.observationHistory[-2]

    def getCurrentObservation(self):
        """
        Returns the GameState object corresponding this agent's current observation
        (the observed state of the game - this may not include
        all of your opponent's agent locations exactly).
        """
        return self.observationHistory[-1]

    def displayDistributionsOverPositions(self, distributions):
        """
        Overlays a distribution over positions onto the pacman board that represents
        an agent's beliefs about the positions of each agent.

        The arg distributions is a tuple or list of util.Counter objects, where the i'th
        Counter has keys that are board positions (x,y) and values that encode the probability
        that agent i is at (x,y).

        If some elements are None, then they will be ignored.  If a Counter is passed to this
        function, it will be displayed. This is helpful for figuring out if your agent is doing
        inference correctly, and does not affect gameplay.
        """
        dists = []
        for dist in distributions:
            if dist != None:
                if not isinstance(dist, util.Counter):
                    raise Exception("Wrong type of distribution")
                dists.append(dist)
            else:
                dists.append(util.Counter())
        if self.display != None and 'updateDistributions' in dir(self.display):
            self.display.updateDistributions(dists)
        else:
            self._distributions = dists  # These can be read by pacclient.py


class TimeoutAgent(Agent):
    """
    A random agent that takes too much time. Taking
    too much time results in penalties and random moves.
    """

    def __init__(self, index):
        self.index = index

    def getAction(self, state):
        import random
        import time
        time.sleep(2.0)
        return random.choice(state.getLegalActions(self.index))


class GenesAgent(CaptureAgent):

    def __init__(self, index, genes=None):
        if genes is None:
            self.genes = Genes(16 * 32 + 8 + 2, 5, Genes.Metaparameters())
        else:
            self.genes = genes
        # for i in range(0, 1000):
        #     self.genes.mutate()
        self.neurons = None
        self.startingPos = None
        self.maxPathDist = 0
        self.prevPosList = []
        self.numCarried = 0
        self.prevNumCarrying = 0
        CaptureAgent.__init__(self, index)

    def _makeInput(self, gameState):
        walls = gameState.getWalls()
        capsules = gameState.getCapsules()
        width = gameState.getWalls().width
        height = gameState.getWalls().height
        # make num food carrying / has swallowed capsules an input?
        # theoretically the agent could learn this through recurrent connections (i.e. memory), but the probability
        # of this occuring seems extremely low
        ret = [0] * (8 + width * height + 2)
        if self.red:
            team = gameState.getRedTeamIndices()
            enemy = gameState.getBlueTeamIndices()
            food = gameState.getRedFood()
            food2 = gameState.getBlueFood()
            for x in range(width):
                for y in range(height):
                    if walls[x][y]:
                        ret[x * height + y] = 1
                    elif food[x][y]:
                        ret[x * height + y] = 2
                    elif food2[x][y]:
                        ret[x * height + y] = 3
            for x, y in capsules:
                ret[x * height + y] = 4
        else:
            enemy = gameState.getRedTeamIndices()
            team = gameState.getBlueTeamIndices()
            food = gameState.getRedFood()
            food2 = gameState.getBlueFood()
            for x in range(width):
                for y in range(height):
                    coord = (width - x) * height - y - 1
                    if walls[x][y]:
                        ret[coord] = 1
                    elif food[x][y]:
                        ret[coord] = 2
                    elif food2[x][y]:
                        ret[coord] = 3
            for x, y in capsules:
                ret[(width - x) * height - y - 1] = 4
        total = width * height

        def assignPosition(arrayIndex, agentIndex):
            position = gameState.getAgentPosition(agentIndex)
            if position is None:
                ret[arrayIndex] = -1
                ret[arrayIndex + 1] = -1
            else:
                if (self.red):
                    ret[arrayIndex] = position[0]
                    ret[arrayIndex+1] = position[1]
                else:
                    ret[arrayIndex] = width - position[0] - 1
                    ret[arrayIndex+1] = height - position[1] - 1
        assignPosition(total, team[0])
        assignPosition(total + 2, team[1])
        assignPosition(total + 4, enemy[0])
        assignPosition(total + 6, enemy[1])

        # Last two inputs are whether the other team is scared (0, 1) and num carrying (0, 20)
        ret[-1] = gameState.data.agentStates[self.index].numCarrying
        isScary = 0
        if self.red:
            otherTeam = gameState.getBlueTeamIndices()
        else:
            otherTeam = gameState.getRedTeamIndices()
        for index in otherTeam:
            if gameState.data.agentStates[index].scaredTimer > 0:
                isScary = 1
                break
        ret[-2] = isScary
        return ret

    def chooseAction(self, gameState):
        curPos = gameState.getAgentPosition(self.index)
        if self.startingPos is None:
            self.startingPos = curPos
        curPathDist = self.getMazeDistance(curPos, self.startingPos)
        if curPathDist > self.maxPathDist:
            self.maxPathDist = curPathDist
        # self.prevPosList.append(curPos)
        # if len(self.prevPosList) > 25:
        #     # Error if in same two spots for 25 positions
        #     pos = self.prevPosList[0]
        #     allEqual = True
        #     for p in self.prevPosList:
        #         if p[0] != pos[0] and p[1] != pos[1]:
        #             allEqual = False
        #             break
        #     if allEqual:
        #         raise Exception("Agent idle. Game terminating.")
        #     self.prevPosList.pop(0)
        """
        curNumCarrying = gameState.data.agentStates[self.index].numCarrying
        if curNumCarrying > self.prevNumCarrying:
            self.numCarried += 1
        self.prevNumCarrying = curNumCarrying
        """

        self.neurons = self.genes.feed_sensor_values(
            self._makeInput(gameState), self.neurons)
        output = self.genes.extract_output_values(self.neurons)
        if self.red:
            values = {"North": output[0], "South": output[1],
                      "East": output[2], "West": output[3], "Stop": output[4]}
        else:
            values = {"South": output[0], "North": output[1],
                      "East": output[3], "West": output[2], "Stop": output[4]}
        legalActions = gameState.getLegalActions(self.index)
        action = max(legalActions, key=lambda dir: values[dir])
        return action
