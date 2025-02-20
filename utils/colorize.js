
const Red = string => `\x1b[31m${string}\x1b[0m`;
const Green = string => `\x1b[32m${string}\x1b[0m`;
const Yellow = string => `\x1b[33m${string}\x1b[0m`;

module.exports = {
    Red, Green, Yellow
}