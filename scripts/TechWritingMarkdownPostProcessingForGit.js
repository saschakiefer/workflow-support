#!/usr/bin/env node

const commandLineArgs = require('command-line-args');
const winston = require('winston');
const path = require('path');
const fs = require('fs');
const shell = require('shelljs');

const _mermaidPath = '_mermaid_diagrams';
const _mermaidTempFile = '~tempInput.txt';

var localFile = '';
var skipDiagrams = false;

// Logger
const myFormat = winston.format.printf(({
    level,
    message,
    label,
    timestamp
}) => {
    return `${timestamp} ${level}: ${message}`;
});

const logger = winston.createLogger({
    format: winston.format.combine(
        winston.format.timestamp(),
        myFormat
    ),
    transports: [new winston.transports.Console()]
});

var inputFile = '';
var outputFile = '';
var mermaidPath = '';

// "Man Pages"
function helpOutput() {
    console.log("help");
    const commandLineUsage = require('command-line-usage');

    const sections = [{
            header: 'Footnote Post Processing Script',
            content: 'post processing script, that turns a custom inline footnote string with the format ((fn: )) (where ( are curley braces)) into a numbered footnote list, that is also compatible with git. It also parses the mermaid diagrams inside the document to pictures'
        },
        {
            header: 'Options',
            optionList: [{
                name: 'input-file',
                alias: 'i',
                typeLabel: '{underline file}',
                description: 'File to be processed'
            }, {
                name: 'output-file',
                alias: 'o',
                typeLabel: '{underline file}',
                description: 'Processed file'
            }, {
                name: 'help',
                alias: 'h',
                description: 'Print this usage guide.'
            }, {
                name: 'no-diagrams',
                alias: 'n',
                description: 'Skips the diagram generating for performance optimization. Only existing ones will be used. Other links will point to non existing resources.'
            }]
        }
    ];

    const usage = commandLineUsage(sections);
    console.log(usage);
    process.exit(0);
}

// Input Check
function checkOptions() {
    logger.info('===== Checking Input Parameters =====');
    const optionDefinitions = [{
        name: 'input-file',
        alias: 'i',
        type: String
    }, {
        name: 'output-file',
        alias: 'o',
        type: String
    }, {
        name: 'help',
        alias: 'h',
        type: Boolean
    }, {
        name: 'no-diagrams',
        alias: 'n',
        type: Boolean
    }]

    const options = commandLineArgs(optionDefinitions);

    if (Object.keys(options).length === 0) {
        logger.error("No input file and output file specified. Use -h or --help for further information");
        process.exit(4);
    }

    if (options.help) {
        helpOutput();
        process.exit(0);
    }

    if (options['no-diagrams']) {
        skipDiagrams = true;
    }

    if (!options['input-file']) {
        logger.error("No input file specified. Use -h or --help for further information");
        process.exit(4);
    }

    if (!options['output-file']) {
        logger.error("No output file specified. Use -h or --help for further information");
        process.exit(4);
    }

    inputFile = options['input-file'];
    outputFile = options['output-file'];
    mermaidPath = path.join(path.dirname(outputFile), _mermaidPath);

    logger.info('Reading from ' + inputFile);
    logger.info('Writing to ' + outputFile);
    logger.info('Mermaid diagram path: ' + mermaidPath);
}

function processFootNotes() {
    logger.info();
    logger.info('===== Transforming Foot Notes =====');
    var str = localFile;

    var footnoteList = "";
    var counter = 1;


    // Find inline Footnotes in the format 
    // ((fn: <content>))
    var regex = /\{\{fn:.*\}\}/gm;
    var res = str.replace(regex, function (x) {
        var target = '<sup>[' + counter + '](#fn' + counter + ')</sup>';
        // logger.info('Processing text reference: ' + x + ' ==> ' + target);

        var footnoteString = x.substring(5, x.length - 2).trim();
        footnoteString = '<a name="fn' + counter + '">[' + counter + ']</a>: ' + footnoteString + "\n\n";
        // logger.info('Footnote: ' + footnoteString);

        footnoteList = footnoteList + footnoteString;
        counter++;
        return target;
    });

    if (counter > 0) {
        counter = counter - 1
    }

    logger.info(counter + ' Footnote(s) processed');
    footnoteList = '\n\n---\n\n' + footnoteList;
    localFile = res + footnoteList;
}

function processMermaid() {
    logger.info();
    logger.info('===== Processing Mermaid Diagrams =====');
    var str = localFile;

    var footnoteList = "";
    var counter = 1;

    // fenced mermaid blocks
    var regex = /^(([ \t]*`{3,4})([^\n]*)([\s\S]+?)(^[ \t]*\2))/gm;
    var res = str.replace(regex, function (x) {
        var imagePath = '';
        var imagePathRel = ''

        // Get Diagram Name
        var imageRegex = /(%%.*diagramName:).*([\n])/gm;
        var imageNameArray = x.match(imageRegex);
        var imageName = '';

        if (imageNameArray == null || imageNameArray.length < 1) {
            logger.warn("Code Block does not contain a diagram name [%% diagramName:<file_name>]. Block will be ignored.");
            return x;
        }

        imageName = imageNameArray[0].trim();
        imageNameArray = imageName.split(':');

        if (imageNameArray.length != 2) {
            logger.warn("Code Block does not contain a valid diagram name [%% diagramName:<file_name>]. Block will be ignored.");
            return x;
        }

        // Assemble file names and paths
        imageName = imageNameArray[1] + '.png';
        imagePathRel = path.join('.', _mermaidPath, imageName);
        imagePath = path.join(mermaidPath, imageName);

        if (!skipDiagrams) {
            // Create Subdir if it does not exist
            if (!fs.existsSync(mermaidPath)) {
                fs.mkdirSync(mermaidPath);
                logger.info(mermaidPath + ' created');
            }


            // Cut fence block from diagram content
            var contentArray = x.split('\n');
            contentArray.pop(); // remove trailing ````
            contentArray.splice(0, 1); // remove leading ```mermaid

            // Create temp input file
            try {
                fs.writeFileSync(path.join(mermaidPath, _mermaidTempFile), contentArray.join('\n'));
            } catch (error) {
                logger.warn(error);
                return x;
            }

            // Execute mermaid CLI
            shell.exec(__dirname + '/../node_modules/.bin/mmdc -w 2048 -H 1536 -c ' +
                path.join(__dirname, 'mermaidConfig.json') +
                ' -i ' + path.join(mermaidPath, _mermaidTempFile) +
                ' -o ' + imagePath);


            logger.info("Diagram created at: " + imagePath);
        }

        counter++;
        return '![' + imageName + '](' + imagePathRel + ')';
    });

    // Delete temp file
    if (!skipDiagrams) {
        try {
            fs.unlinkSync(path.join(mermaidPath, _mermaidTempFile));
            logger.info('Successfully deleted ' + path.join(mermaidPath, _mermaidTempFile));
        } catch (err) {
            logger.warn('Could not delete ' + path.join(mermaidPath, _mermaidTempFile) + '. Please delete manually.')
        }
    }

    // Correct Counter
    if (counter > 0) {
        counter = counter - 1
    }

    logger.info(counter + ' Diagram(s) processed');
    footnoteList = '\n\n---\n\n' + footnoteList;
    localFile = res + footnoteList;
}

////// MAIN //////
checkOptions();

// Read File in local representation
localFile = fs.readFileSync(inputFile, 'utf8');

processFootNotes();
processMermaid();

fs.writeFileSync(outputFile, localFile);
logger.info();
logger.info(outputFile + ' succesfully created');