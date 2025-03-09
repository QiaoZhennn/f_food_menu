/* eslint-disable max-len, require-jsdoc  */
interface Vertex {
  x: number;
  y: number;
}

interface BoundingPoly {
  vertices: Vertex[];
  normalizedVertices?: any[];
}

interface TextAnnotation {
  description: string;
  boundingPoly: BoundingPoly;
  locale?: string;
  [key: string]: any;
}

export class MenuAnalysisService {
  // Main function to merge text annotations into lines
  mergeTextLines(textAnnotations: TextAnnotation[]): TextAnnotation[] {
    if (!textAnnotations || textAnnotations.length <= 1) {
      return textAnnotations;
    }

    // Skip the first annotation (full text) and just process individual words
    const wordAnnotations = textAnnotations.slice(1);

    // Detect text orientation
    const orientation = this.detectTextOrientation(wordAnnotations);

    // Group words based on orientation
    const lines = orientation === "horizontal" ?
      this.groupIntoLines(wordAnnotations) :
      this.groupIntoVerticalLines(wordAnnotations);

    // Merge words in each line into a single bounding box
    const mergedLines = this.mergeLines(lines);

    // Return only the merged line annotations (no full text annotation)
    return mergedLines;
  }

  private groupIntoLines(annotations: TextAnnotation[]): TextAnnotation[][] {
    if (annotations.length === 0) return [];

    // Sort annotations by Y position (top to bottom)
    const sortedAnnotations = [...annotations].sort((a, b) => {
      return this.getCenter(a.boundingPoly).y - this.getCenter(b.boundingPoly).y;
    });

    const lines: TextAnnotation[][] = [];
    let currentLine: TextAnnotation[] = [sortedAnnotations[0]];
    const lineThreshold = this.estimateLineHeight(sortedAnnotations) * 0.6;

    for (let i = 1; i < sortedAnnotations.length; i++) {
      const current = sortedAnnotations[i];
      const prevLineCenter = this.getAverageY(currentLine);
      const currentCenter = this.getCenter(current.boundingPoly).y;

      // Check if current annotation is on the same line
      if (Math.abs(currentCenter - prevLineCenter) < lineThreshold) {
        currentLine.push(current);
      } else {
        // Sort the line by X position (left to right)
        currentLine.sort((a, b) =>
          this.getCenter(a.boundingPoly).x - this.getCenter(b.boundingPoly).x
        );
        lines.push(currentLine);
        currentLine = [current];
      }
    }

    // Add the last line
    if (currentLine.length > 0) {
      currentLine.sort((a, b) =>
        this.getCenter(a.boundingPoly).x - this.getCenter(b.boundingPoly).x
      );
      lines.push(currentLine);
    }

    return lines;
  }

  private mergeLines(lines: TextAnnotation[][]): TextAnnotation[] {
    return lines.map((line) => {
      // Find the minimum and maximum coordinates for the merged bounding box
      let minX = Infinity; let minY = Infinity;
      let maxX = -Infinity; let maxY = -Infinity;

      // Combine text from all annotations in the line
      const mergedText = line.map((a) => a.description).join(" ");

      // Find the boundaries of the line's bounding box
      line.forEach((annotation) => {
        annotation.boundingPoly.vertices.forEach((vertex) => {
          minX = Math.min(minX, vertex.x || 0);
          minY = Math.min(minY, vertex.y || 0);
          maxX = Math.max(maxX, vertex.x || 0);
          maxY = Math.max(maxY, vertex.y || 0);
        });
      });

      // Create a new merged annotation
      return {
        description: mergedText,
        boundingPoly: {
          vertices: [
            {x: minX, y: minY}, // top-left
            {x: maxX, y: minY}, // top-right
            {x: maxX, y: maxY}, // bottom-right
            {x: minX, y: maxY}, // bottom-left
          ],
          normalizedVertices: [],
        },
        locale: line[0].locale || "en",
      };
    });
  }

  // Helper functions
  private getCenter(boundingPoly: BoundingPoly): {x: number, y: number} {
    const vertices = boundingPoly.vertices;
    const x = vertices.reduce((sum, v) => sum + (v.x || 0), 0) / vertices.length;
    const y = vertices.reduce((sum, v) => sum + (v.y || 0), 0) / vertices.length;
    return {x, y};
  }

  private getAverageY(annotations: TextAnnotation[]): number {
    return annotations.reduce((sum, ann) =>
      sum + this.getCenter(ann.boundingPoly).y, 0
    ) / annotations.length;
  }

  private estimateLineHeight(annotations: TextAnnotation[]): number {
    // Calculate average height of annotations
    const heights = annotations.map((ann) => {
      const vertices = ann.boundingPoly.vertices;
      const topY = Math.min(...vertices.map((v) => v.y || 0));
      const bottomY = Math.max(...vertices.map((v) => v.y || 0));
      return bottomY - topY;
    });

    return heights.reduce((sum, h) => sum + h, 0) / heights.length;
  }

  private detectTextOrientation(annotations: TextAnnotation[]): "horizontal" | "vertical" {
    let horizontalCount = 0;
    let verticalCount = 0;

    annotations.forEach((ann) => {
      const vertices = ann.boundingPoly.vertices;
      const width = Math.max(...vertices.map((v) => v.x || 0)) - Math.min(...vertices.map((v) => v.x || 0));
      const height = Math.max(...vertices.map((v) => v.y || 0)) - Math.min(...vertices.map((v) => v.y || 0));

      if (width > height) {
        horizontalCount++;
      } else {
        verticalCount++;
      }
    });

    return horizontalCount > verticalCount ? "horizontal" : "vertical";
  }

  private groupIntoVerticalLines(annotations: TextAnnotation[]): TextAnnotation[][] {
    if (annotations.length === 0) return [];

    // Sort by X position (left to right)
    const sortedAnnotations = [...annotations].sort((a, b) => {
      return this.getCenter(a.boundingPoly).x - this.getCenter(b.boundingPoly).x;
    });

    const lines: TextAnnotation[][] = [];
    let currentLine: TextAnnotation[] = [sortedAnnotations[0]];
    const lineThreshold = this.estimateLineWidth(sortedAnnotations) * 0.6;

    for (let i = 1; i < sortedAnnotations.length; i++) {
      const current = sortedAnnotations[i];
      const prevLineCenter = this.getAverageX(currentLine);
      const currentCenter = this.getCenter(current.boundingPoly).x;

      if (Math.abs(currentCenter - prevLineCenter) < lineThreshold) {
        currentLine.push(current);
      } else {
        // Sort by Y position (top to bottom)
        currentLine.sort((a, b) =>
          this.getCenter(a.boundingPoly).y - this.getCenter(b.boundingPoly).y
        );
        lines.push(currentLine);
        currentLine = [current];
      }
    }

    if (currentLine.length > 0) {
      currentLine.sort((a, b) =>
        this.getCenter(a.boundingPoly).y - this.getCenter(b.boundingPoly).y
      );
      lines.push(currentLine);
    }

    return lines;
  }

  private getAverageX(annotations: TextAnnotation[]): number {
    return annotations.reduce((sum, ann) =>
      sum + this.getCenter(ann.boundingPoly).x, 0
    ) / annotations.length;
  }

  private estimateLineWidth(annotations: TextAnnotation[]): number {
    const widths = annotations.map((ann) => {
      const vertices = ann.boundingPoly.vertices;
      const leftX = Math.min(...vertices.map((v) => v.x || 0));
      const rightX = Math.max(...vertices.map((v) => v.x || 0));
      return rightX - leftX;
    });

    return widths.reduce((sum, w) => sum + w, 0) / widths.length;
  }
}
